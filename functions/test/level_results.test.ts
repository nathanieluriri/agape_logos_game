import * as admin from "firebase-admin";
import request from "supertest";
import {createApp} from "../src/app";

const app = createApp();

// Mints a brand new user in the Auth emulator and returns an ID token + uid.
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

describe("POST /levels/:levelId/result", () => {
  test("401 when no Authorization header", async () => {
    const res = await request(app)
      .post("/levels/3/result")
      .set("idempotency-key", "r-noauth")
      .send({id: "r-noauth", levelId: 3, score: 100, completedAt: 5});
    expect(res.status).toBe(401);
  });

  test("400 when idempotency-key header is missing", async () => {
    const {idToken} = await mintUser();
    const res = await request(app)
      .post("/levels/3/result")
      .set("Authorization", `Bearer ${idToken}`)
      .send({id: "r-x", levelId: 3, score: 100, completedAt: 5});
    expect(res.status).toBe(400);
  });

  test("400 when score is not an integer", async () => {
    const {idToken} = await mintUser();
    const res = await request(app)
      .post("/levels/3/result")
      .set("Authorization", `Bearer ${idToken}`)
      .set("idempotency-key", "r-badscore")
      .send({id: "r-badscore", levelId: 3, score: "high", completedAt: 5});
    expect(res.status).toBe(400);
  });

  test("400 when idempotency-key contains a slash", async () => {
    const {idToken, uid} = await mintUser();
    const res = await request(app)
      .post("/levels/3/result")
      .set("Authorization", `Bearer ${idToken}`)
      .set("idempotency-key", "bad/key")
      .send({levelId: 3, score: 100, completedAt: 5});
    expect(res.status).toBe(400);
    const all = await admin
      .firestore()
      .collection("users").doc(uid)
      .collection("levelResults")
      .get();
    expect(all.size).toBe(0);
  });

  test("200 writes the doc and replays are idempotent", async () => {
    const {idToken, uid} = await mintUser();
    const key = "r-happy";
    const post = () =>
      request(app)
        .post("/levels/3/result")
        .set("Authorization", `Bearer ${idToken}`)
        .set("idempotency-key", key)
        .send({id: key, levelId: 3, score: 100, completedAt: 5, synced: false});

    const first = await post();
    expect(first.status).toBe(200);
    expect(first.body).toEqual({ok: true});

    const second = await post();
    expect(second.status).toBe(200);

    const snap = await admin
      .firestore()
      .collection("users").doc(uid)
      .collection("levelResults").doc(key)
      .get();
    expect(snap.exists).toBe(true);
    expect(snap.data()).toMatchObject({levelId: 3, score: 100, completedAt: 5, uid});

    const all = await admin
      .firestore()
      .collection("users").doc(uid)
      .collection("levelResults")
      .get();
    expect(all.size).toBe(1);
  });
});
