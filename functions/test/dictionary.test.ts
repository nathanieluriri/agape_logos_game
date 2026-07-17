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

async function seed(uid: string): Promise<void> {
  const db = admin.firestore();
  const mk = (
    key: string,
    tier: string,
    answers: {word: string; length: number; definition: string | null}[],
  ) => ({tier, rackSize: key.length, letters: key.split(""), letterKey: key, anchor: key, answers, answerCount: answers.length});
  const batch = db.batch();
  batch.set(db.collection("puzzles").doc("CAB"), mk("CAB", "easy", [
    {word: "CAB", length: 3, definition: "a taxi"},
    {word: "ABC", length: 3, definition: null},
  ]));
  batch.set(db.collection("puzzles").doc("ZIP"), mk("ZIP", "medium", [
    {word: "ZIP", length: 3, definition: "fasten"},
  ]));
  batch.set(db.collection("puzzles").doc("OPEN"), mk("OPEN", "hard", [
    {word: "OPEN", length: 4, definition: "not shut"},
  ]));
  const a = db.collection("users").doc(uid).collection("assignments");
  batch.set(a.doc("CAB"), {puzzleId: "CAB", tier: "easy", assignedAt: 1, completed: true, completedAt: 2});
  batch.set(a.doc("ZIP"), {puzzleId: "ZIP", tier: "medium", assignedAt: 1, completed: true, completedAt: 3});
  batch.set(a.doc("OPEN"), {puzzleId: "OPEN", tier: "hard", assignedAt: 1, completed: false, completedAt: null});
  await batch.commit();
}

jest.setTimeout(90000);

describe("GET /me/dictionary", () => {
  test("returns solved words from completed puzzles only, deduped with definitions", async () => {
    const {idToken, uid} = await mintUser();
    await seed(uid);
    const res = await request(app).get("/me/dictionary").set("Authorization", `Bearer ${idToken}`);
    expect(res.status).toBe(200);
    const words = res.body.entries.map((e: {word: string}) => e.word.toUpperCase());
    // OPEN excluded (its assignment is incomplete); ABC + CAB + ZIP present, sorted.
    expect(words).toEqual(["ABC", "CAB", "ZIP"]);
    const cab = res.body.entries.find((e: {word: string}) => e.word.toUpperCase() === "CAB");
    expect(cab.definition).toBe("a taxi");
    expect(cab.tier).toBe("easy");
  });

  test("empty list for a user with no completed puzzles", async () => {
    const {idToken} = await mintUser();
    const res = await request(app).get("/me/dictionary").set("Authorization", `Bearer ${idToken}`);
    expect(res.status).toBe(200);
    expect(res.body.entries).toEqual([]);
  });

  test("401 without a token", async () => {
    const res = await request(app).get("/me/dictionary");
    expect(res.status).toBe(401);
  });
});
