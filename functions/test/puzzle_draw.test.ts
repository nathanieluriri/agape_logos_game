import {describe, test, expect, beforeEach} from "@jest/globals";
import * as admin from "firebase-admin";
import request from "supertest";
import {createApp} from "../src/app";
import {decryptAnswer} from "../src/crypto/answer_cipher";

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

async function seedPool(): Promise<void> {
  const db = admin.firestore();
  const existing = await db.collection("puzzles").get();
  await Promise.all(existing.docs.map((d) => d.ref.delete()));
  const mk = (key: string, tier: string) => ({
    tier, rackSize: key.length, letters: key.split(""), letterKey: key,
    anchor: key, answers: [{word: key, length: key.length, definition: null}], answerCount: 1,
  });
  const batch = db.batch();
  for (const k of ["AAA", "BBB", "CCC", "DDD", "EEE"]) batch.set(db.collection("puzzles").doc(k), mk(k, "easy"));
  for (const k of ["FFFF", "GGGG"]) batch.set(db.collection("puzzles").doc(k), mk(k, "medium"));
  await batch.commit();
}

jest.setTimeout(90000);

describe("POST /puzzles/draw", () => {
  beforeEach(seedPool);

  test("401 without a token", async () => {
    const res = await request(app).post("/puzzles/draw").set("idempotency-key", "d1").send({easy: 1});
    expect(res.status).toBe(401);
  });

  test("answers are encrypted per-user and decrypt with the answer key", async () => {
    const {idToken} = await mintUser();
    const draw = await request(app).post("/puzzles/draw")
      .set("Authorization", `Bearer ${idToken}`).set("idempotency-key", "enc1").send({easy: 1});
    const puzzle = draw.body.byTier.easy.puzzles[0];
    // No plaintext answer leaks over the wire.
    expect(puzzle.answers[0].word).toBeUndefined();
    expect(puzzle.answers[0].definition).toBeUndefined();
    expect(typeof puzzle.answers[0].enc).toBe("string");
    expect(puzzle.answers[0].length).toBeGreaterThan(0);
    // The caller's key (from /me/answer-key) decrypts it. In this seed the word
    // equals the letterKey.
    const keyRes = await request(app).get("/me/answer-key")
      .set("Authorization", `Bearer ${idToken}`);
    const key = Buffer.from(keyRes.body.key, "base64");
    const clear = JSON.parse(decryptAnswer(key, puzzle.answers[0].enc));
    expect(clear.w).toBe(puzzle.letterKey);
  });

  test("400 when all counts are zero", async () => {
    const {idToken} = await mintUser();
    const res = await request(app).post("/puzzles/draw")
      .set("Authorization", `Bearer ${idToken}`).set("idempotency-key", "d0").send({easy: 0});
    expect(res.status).toBe(400);
  });

  test("draws unseen per tier and reports shortfall", async () => {
    const {idToken} = await mintUser();
    const res = await request(app).post("/puzzles/draw")
      .set("Authorization", `Bearer ${idToken}`).set("idempotency-key", "d2")
      .send({easy: 3, medium: 5});
    expect(res.status).toBe(200);
    expect(res.body.byTier.easy.assigned).toBe(3);
    expect(res.body.byTier.easy.puzzles).toHaveLength(3);
    expect(res.body.byTier.medium.assigned).toBe(2);
    expect(res.body.byTier.medium.requested).toBe(5);
    expect(res.body.shortfall).toBe(true);
  });

  test("a second draw excludes already-assigned puzzles", async () => {
    const {idToken} = await mintUser();
    const post = (key: string, body: object) => request(app).post("/puzzles/draw")
      .set("Authorization", `Bearer ${idToken}`).set("idempotency-key", key).send(body);
    const first = await post("a", {easy: 3});
    const second = await post("b", {easy: 3});
    const firstIds = first.body.byTier.easy.puzzles.map((p: {letterKey: string}) => p.letterKey);
    const secondIds = second.body.byTier.easy.puzzles.map((p: {letterKey: string}) => p.letterKey);
    expect(secondIds.every((id: string) => !firstIds.includes(id))).toBe(true);
    expect(second.body.byTier.easy.assigned).toBe(2);
  });

  test("idempotency-key replay returns the same batch and assigns nothing new", async () => {
    const {idToken, uid} = await mintUser();
    const post = () => request(app).post("/puzzles/draw")
      .set("Authorization", `Bearer ${idToken}`).set("idempotency-key", "same").send({easy: 2});
    const first = await post();
    const second = await post();
    const ids1 = first.body.byTier.easy.puzzles.map((p: {letterKey: string}) => p.letterKey).sort();
    const ids2 = second.body.byTier.easy.puzzles.map((p: {letterKey: string}) => p.letterKey).sort();
    expect(ids2).toEqual(ids1);
    const assigned = await admin.firestore().collection("users").doc(uid).collection("assignments").get();
    expect(assigned.size).toBe(2);
  });

  test("GET /puzzles/assigned?status=completed returns only completed puzzles", async () => {
    const {idToken} = await mintUser();
    // Draw two, complete one.
    const draw = await request(app).post("/puzzles/draw")
      .set("Authorization", `Bearer ${idToken}`).set("idempotency-key", "cd1").send({easy: 2});
    const ids = draw.body.byTier.easy.puzzles.map((p: {letterKey: string}) => p.letterKey);
    await request(app).post(`/puzzles/${ids[0]}/result`)
      .set("Authorization", `Bearer ${idToken}`).set("idempotency-key", "cr1")
      .send({score: 5, completedAt: 1});

    const done = await request(app).get("/puzzles/assigned?status=completed")
      .set("Authorization", `Bearer ${idToken}`);
    expect(done.status).toBe(200);
    const doneIds = done.body.puzzles.map((p: {letterKey: string}) => p.letterKey);
    expect(doneIds).toContain(ids[0]);
    expect(doneIds).not.toContain(ids[1]);
    expect(done.body.puzzles.every((p: {completed: boolean}) => p.completed)).toBe(true);
  });

  test("a guest (anonymous) user can draw, get an answer key, and post a result", async () => {
    const {idToken} = await mintUser(); // tokenless sign-up == anonymous guest
    const draw = await request(app).post("/puzzles/draw")
      .set("Authorization", `Bearer ${idToken}`).set("idempotency-key", "g1").send({easy: 1});
    expect(draw.status).toBe(200);
    expect(draw.body.byTier.easy.puzzles).toHaveLength(1);
    const id = draw.body.byTier.easy.puzzles[0].letterKey;

    const key = await request(app).get("/me/answer-key")
      .set("Authorization", `Bearer ${idToken}`);
    expect(key.status).toBe(200);
    expect(typeof key.body.key).toBe("string");

    const result = await request(app).post(`/puzzles/${id}/result`)
      .set("Authorization", `Bearer ${idToken}`).set("idempotency-key", "gr1")
      .send({score: 3, completedAt: 1});
    expect(result.status).toBe(200);
  });
});
