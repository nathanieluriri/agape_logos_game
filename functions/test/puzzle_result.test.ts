import {describe, test, expect} from "@jest/globals";
import * as admin from "firebase-admin";
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

describe("POST /puzzles/:puzzleId/result", () => {
  test("401 without token", async () => {
    const res = await request(app).post("/puzzles/NOW/result").set("idempotency-key", "r1").send({score: 1, completedAt: 1});
    expect(res.status).toBe(401);
  });

  test("400 on lowercase puzzleId", async () => {
    const {idToken} = await mintUser();
    const res = await request(app).post("/puzzles/now/result")
      .set("Authorization", `Bearer ${idToken}`).set("idempotency-key", "r2").send({score: 1, completedAt: 1});
    expect(res.status).toBe(400);
  });

  test("records the result and flips the assignment to completed (idempotent)", async () => {
    const {idToken, uid} = await mintUser();
    const db = admin.firestore();
    await db.collection("users").doc(uid).collection("assignments").doc("NOW")
      .set({puzzleId: "NOW", tier: "easy", assignedAt: 1, completed: false, completedAt: null});

    const post = () => request(app).post("/puzzles/NOW/result")
      .set("Authorization", `Bearer ${idToken}`).set("idempotency-key", "r3")
      .send({score: 50, completedAt: 7});

    const first = await post();
    expect(first.status).toBe(200);
    expect(first.body).toEqual({ok: true});
    await post();

    const result = await db.collection("users").doc(uid).collection("puzzleResults").doc("r3").get();
    expect(result.data()).toMatchObject({puzzleId: "NOW", score: 50, completedAt: 7, uid});
    const assignment = await db.collection("users").doc(uid).collection("assignments").doc("NOW").get();
    expect(assignment.data()).toMatchObject({completed: true, completedAt: 7});
    const allResults = await db.collection("users").doc(uid).collection("puzzleResults").get();
    expect(allResults.size).toBe(1);
  });

  test("result for an unassigned puzzle still records and creates a completed assignment", async () => {
    const {idToken, uid} = await mintUser();
    const res = await request(app).post("/puzzles/CAT/result")
      .set("Authorization", `Bearer ${idToken}`).set("idempotency-key", "r4").send({score: 9, completedAt: 3});
    expect(res.status).toBe(200);
    const assignment = await admin.firestore().collection("users").doc(uid).collection("assignments").doc("CAT").get();
    expect(assignment.exists).toBe(true);
    expect(assignment.data()).toMatchObject({completed: true});
  });
});
