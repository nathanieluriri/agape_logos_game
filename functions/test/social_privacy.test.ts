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

describe("PUT /me/privacy", () => {
  test("401 without auth", async () => {
    const res = await request(app).put("/me/privacy").set("idempotency-key", "p0").send({public: true});
    expect(res.status).toBe(401);
  });

  test("defaults private, then flips public and GET /me reflects it", async () => {
    const {idToken} = await mintUser();
    const before = await request(app).get("/me").set("Authorization", `Bearer ${idToken}`);
    expect(before.body.public).toBe(false);

    const put = await request(app).put("/me/privacy")
      .set("Authorization", `Bearer ${idToken}`).set("idempotency-key", "p1")
      .send({public: true});
    expect(put.status).toBe(200);
    expect(put.body.ok).toBe(true);

    const after = await request(app).get("/me").set("Authorization", `Bearer ${idToken}`);
    expect(after.body.public).toBe(true);
  });

  test("rejects an unknown body key (strict) and a missing idempotency-key", async () => {
    const {idToken} = await mintUser();
    const bad = await request(app).put("/me/privacy")
      .set("Authorization", `Bearer ${idToken}`).set("idempotency-key", "p2")
      .send({public: true, sneaky: 1});
    expect(bad.status).toBe(400);
    const noKey = await request(app).put("/me/privacy")
      .set("Authorization", `Bearer ${idToken}`).send({public: true});
    expect(noKey.status).toBe(400);
  });
});
