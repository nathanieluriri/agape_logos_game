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

const auth = (t: string) => ({Authorization: `Bearer ${t}`});

describe("friends", () => {
  test("request then accept makes both sides friends and clears the request", async () => {
    const a = await mintUser();
    const b = await mintUser();

    const req = await request(app).post("/friends/request")
      .set(auth(a.idToken)).set("idempotency-key", "fr1").send({toUid: b.uid});
    expect(req.status).toBe(200);

    // B sees the incoming request.
    const bIn = await request(app).get("/friends").set(auth(b.idToken));
    expect(bIn.body.requests.map((r: {fromUid: string}) => r.fromUid)).toContain(a.uid);

    const acc = await request(app).post("/friends/respond")
      .set(auth(b.idToken)).set("idempotency-key", "re1").send({fromUid: a.uid, accept: true});
    expect(acc.status).toBe(200);

    const aFriends = await request(app).get("/friends").set(auth(a.idToken));
    const bFriends = await request(app).get("/friends").set(auth(b.idToken));
    expect(aFriends.body.friends.map((f: {uid: string}) => f.uid)).toContain(b.uid);
    expect(bFriends.body.friends.map((f: {uid: string}) => f.uid)).toContain(a.uid);
    // The request is gone after accept.
    expect(bFriends.body.requests).toHaveLength(0);
  });

  test("decline deletes the request and creates no friendship", async () => {
    const a = await mintUser();
    const b = await mintUser();
    await request(app).post("/friends/request")
      .set(auth(a.idToken)).set("idempotency-key", "fr2").send({toUid: b.uid});
    const dec = await request(app).post("/friends/respond")
      .set(auth(b.idToken)).set("idempotency-key", "re2").send({fromUid: a.uid, accept: false});
    expect(dec.status).toBe(200);
    const bFriends = await request(app).get("/friends").set(auth(b.idToken));
    expect(bFriends.body.requests).toHaveLength(0);
    expect(bFriends.body.friends.map((f: {uid: string}) => f.uid)).not.toContain(a.uid);
  });

  test("request by handle resolves the target", async () => {
    const a = await mintUser();
    const b = await mintUser();
    await request(app).put("/me").set(auth(b.idToken)).send({displayName: "Findme"});
    const me = await request(app).get("/me").set(auth(b.idToken));
    const handle = me.body.handle as string;

    const req = await request(app).post("/friends/request")
      .set(auth(a.idToken)).set("idempotency-key", "fr3").send({handle});
    expect(req.status).toBe(200);
    const bIn = await request(app).get("/friends").set(auth(b.idToken));
    expect(bIn.body.requests.map((r: {fromUid: string}) => r.fromUid)).toContain(a.uid);
  });

  test("self-request 400, unknown handle 404, respond to nothing 404", async () => {
    const a = await mintUser();
    const self = await request(app).post("/friends/request")
      .set(auth(a.idToken)).set("idempotency-key", "fr4").send({toUid: a.uid});
    expect(self.status).toBe(400);
    const unknown = await request(app).post("/friends/request")
      .set(auth(a.idToken)).set("idempotency-key", "fr5").send({handle: "nobodyhere999"});
    expect(unknown.status).toBe(404);
    const b = await mintUser();
    const none = await request(app).post("/friends/respond")
      .set(auth(a.idToken)).set("idempotency-key", "re3").send({fromUid: b.uid, accept: true});
    expect(none.status).toBe(404);
  });
});
