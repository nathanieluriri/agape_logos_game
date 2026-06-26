import {describe, test, expect} from "@jest/globals";
import * as admin from "firebase-admin";
import request from "supertest";
import {createApp} from "../src/app";

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

async function seedPoolAndAssign(uid: string): Promise<void> {
  const db = admin.firestore();
  const mk = (key: string) => ({
    tier: "easy", rackSize: key.length, letters: key.split(""), letterKey: key,
    anchor: key, answers: [{word: key, length: key.length, definition: null}], answerCount: 1,
  });
  const batch = db.batch();
  for (const k of ["AAA", "BBB"]) batch.set(db.collection("puzzles").doc(k), mk(k));
  const a = db.collection("users").doc(uid).collection("assignments");
  batch.set(a.doc("AAA"), {puzzleId: "AAA", tier: "easy", assignedAt: 1, completed: false, completedAt: null});
  batch.set(a.doc("BBB"), {puzzleId: "BBB", tier: "easy", assignedAt: 1, completed: true, completedAt: 2});
  batch.set(a.doc("GONE"), {puzzleId: "GONE", tier: "easy", assignedAt: 1, completed: false, completedAt: null});
  await batch.commit();
}

jest.setTimeout(90000);

describe("GET /puzzles/assigned", () => {
  test("incomplete (default) returns only not-completed, resolving references; missing pool docs skipped", async () => {
    const {idToken, uid} = await mintUser();
    await seedPoolAndAssign(uid);
    const res = await request(app).get("/puzzles/assigned").set("Authorization", `Bearer ${idToken}`);
    expect(res.status).toBe(200);
    const keys = res.body.puzzles.map((p: {letterKey: string}) => p.letterKey).sort();
    expect(keys).toEqual(["AAA"]);
    expect(res.body.puzzles[0].completed).toBe(false);
  });

  test("status=all returns completed and incomplete (still skipping missing pool docs)", async () => {
    const {idToken, uid} = await mintUser();
    await seedPoolAndAssign(uid);
    const res = await request(app).get("/puzzles/assigned?status=all").set("Authorization", `Bearer ${idToken}`);
    const keys = res.body.puzzles.map((p: {letterKey: string}) => p.letterKey).sort();
    expect(keys).toEqual(["AAA", "BBB"]);
  });

  test("400 on bad status", async () => {
    const {idToken} = await mintUser();
    const res = await request(app).get("/puzzles/assigned?status=weird").set("Authorization", `Bearer ${idToken}`);
    expect(res.status).toBe(400);
  });
});
