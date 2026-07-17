import {describe, test, expect} from "@jest/globals";
import request from "supertest";
import {createApp} from "../src/app";

jest.setTimeout(90000);
const app = createApp();

async function mintUser(): Promise<{idToken: string; uid: string}> {
  const host = process.env.FIREBASE_AUTH_EMULATOR_HOST;
  const res = await fetch(
    `http://${host}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-key`,
    {method: "POST", headers: {"Content-Type": "application/json"}, body: JSON.stringify({returnSecureToken: true})},
  );
  const data = (await res.json()) as {idToken: string; localId: string};
  return {idToken: data.idToken, uid: data.localId};
}

async function setup(idToken: string, name: string, isPublic: boolean): Promise<void> {
  await request(app).put("/me").set("Authorization", `Bearer ${idToken}`).send({displayName: name});
  await request(app).put("/me/privacy").set("Authorization", `Bearer ${idToken}`)
    .set("idempotency-key", `k-${name}`).send({public: isPublic});
}

describe("GET /users/search + /users/:uid/public", () => {
  test("search returns only public profiles, minimal projection, no private leak", async () => {
    const pub = await mintUser();
    const priv = await mintUser();
    const me = await mintUser();
    await setup(pub.idToken, "Publicalice", true);
    await setup(priv.idToken, "Privatebob", false);

    const res = await request(app).get("/users/search?q=publicalice")
      .set("Authorization", `Bearer ${me.idToken}`);
    expect(res.status).toBe(200);
    const uids = res.body.users.map((u: {uid: string}) => u.uid);
    expect(uids).toContain(pub.uid);

    const priv2 = await request(app).get("/users/search?q=privatebob")
      .set("Authorization", `Bearer ${me.idToken}`);
    expect(priv2.body.users.map((u: {uid: string}) => u.uid)).not.toContain(priv.uid);

    const one = res.body.users.find((u: {uid: string}) => u.uid === pub.uid);
    expect(one.coins).toBeUndefined();
    expect(one.inventory).toBeUndefined();
    expect(typeof one.handle).toBe("string");
  });

  test("public detail is visible for a public user, 403 for a private non-friend", async () => {
    const pub = await mintUser();
    const priv = await mintUser();
    const me = await mintUser();
    await setup(pub.idToken, "Opencarol", true);
    await setup(priv.idToken, "Shydave", false);

    const ok = await request(app).get(`/users/${pub.uid}/public`)
      .set("Authorization", `Bearer ${me.idToken}`);
    expect(ok.status).toBe(200);
    expect(ok.body.profile.uid).toBe(pub.uid);
    expect(Array.isArray(ok.body.recentMatches)).toBe(true);

    const forbidden = await request(app).get(`/users/${priv.uid}/public`)
      .set("Authorization", `Bearer ${me.idToken}`);
    expect(forbidden.status).toBe(403);
  });

  test("you can always view your own profile even while private", async () => {
    const {idToken, uid} = await mintUser();
    await setup(idToken, "Selfeve", false);
    const res = await request(app).get(`/users/${uid}/public`)
      .set("Authorization", `Bearer ${idToken}`);
    expect(res.status).toBe(200);
    expect(res.body.profile.uid).toBe(uid);
  });
});
