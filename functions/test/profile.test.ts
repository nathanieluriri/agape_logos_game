import request from "supertest";
import {createApp} from "../src/app";
import {describe, test, expect} from "@jest/globals";

const app = createApp();

async function mintUser(): Promise<{idToken: string; uid: string}> {
  const host = process.env.FIREBASE_AUTH_EMULATOR_HOST;
  const res = await fetch(
    `http://${host}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-key`,
    {
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify({returnSecureToken: true}),
    },
  );
  const data = (await res.json()) as {idToken: string; localId: string};
  return {idToken: data.idToken, uid: data.localId};
}

describe("/me profile", () => {
  test("401 without auth on GET and PUT", async () => {
    expect((await request(app).get("/me")).status).toBe(401);
    expect((await request(app).put("/me").send({displayName: "x"})).status).toBe(401);
  });

  test("GET /me auto-creates defaults and is idempotent", async () => {
    const {idToken, uid} = await mintUser();
    const auth = `Bearer ${idToken}`;
    const first = await request(app).get("/me").set("Authorization", auth);
    expect(first.status).toBe(200);
    expect(first.body).toMatchObject({
      uid,
      displayName: "Player",
      avatarId: "avatar_01",
      locale: "en",
      soundEnabled: true,
      musicEnabled: true,
      highestLevel: 0,
      totalScore: 0,
      coins: 0,
      inventory: {},
    });
    expect(typeof first.body.createdAt).toBe("number");
    expect(first.body.createdAt).toBeGreaterThan(0);

    const second = await request(app).get("/me").set("Authorization", auth);
    expect(second.body.createdAt).toBe(first.body.createdAt);
  });

  test("GET /me/coins returns the balance and auto-provisions at 0", async () => {
    const {idToken} = await mintUser();
    const res = await request(app).get("/me/coins").set("Authorization", `Bearer ${idToken}`);
    expect(res.status).toBe(200);
    expect(res.body).toEqual({coins: 0});
  });

  test("GET /me/coins 401 without auth", async () => {
    expect((await request(app).get("/me/coins")).status).toBe(401);
  });

  test("GET /me/answer-key returns a 32-byte base64 key to the owner", async () => {
    const {idToken} = await mintUser();
    const res = await request(app).get("/me/answer-key").set("Authorization", `Bearer ${idToken}`);
    expect(res.status).toBe(200);
    expect(typeof res.body.key).toBe("string");
    expect(Buffer.from(res.body.key, "base64").length).toBe(32);
  });

  test("GET /me/answer-key 401 without auth", async () => {
    expect((await request(app).get("/me/answer-key")).status).toBe(401);
  });

  test("PUT /me updates editable fields and bumps updatedAt", async () => {
    const {idToken} = await mintUser();
    const auth = `Bearer ${idToken}`;
    const created = await request(app).get("/me").set("Authorization", auth);
    const res = await request(app)
      .put("/me")
      .set("Authorization", auth)
      .send({displayName: "Trinity", soundEnabled: false});
    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({displayName: "Trinity", soundEnabled: false});
    expect(res.body.updatedAt).toBeGreaterThanOrEqual(created.body.updatedAt);
  });

  test("PUT /me rejects a read-only field", async () => {
    const {idToken} = await mintUser();
    const res = await request(app)
      .put("/me")
      .set("Authorization", `Bearer ${idToken}`)
      .send({totalScore: 9999});
    expect(res.status).toBe(400);
  });

  test("PUT /me rejects bad types", async () => {
    const {idToken} = await mintUser();
    const auth = `Bearer ${idToken}`;
    const tooLong = await request(app)
      .put("/me").set("Authorization", auth).send({displayName: "x".repeat(31)});
    expect(tooLong.status).toBe(400);
    const badBool = await request(app)
      .put("/me").set("Authorization", auth).send({soundEnabled: "yes"});
    expect(badBool.status).toBe(400);
  });
});
