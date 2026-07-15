import {describe, test, expect} from "@jest/globals";
import * as admin from "firebase-admin";
import request from "supertest";
import {createApp} from "../src/app";
import {kAsyncRoundMs} from "../src/services/match_service";

jest.setTimeout(90000);
const app = createApp();
const auth = (t: string) => ({Authorization: `Bearer ${t}`});

async function mintUser(): Promise<{idToken: string; uid: string}> {
  const host = process.env.FIREBASE_AUTH_EMULATOR_HOST;
  const res = await fetch(
    `http://${host}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-key`,
    {method: "POST", headers: {"Content-Type": "application/json"}, body: JSON.stringify({returnSecureToken: true})},
  );
  const data = (await res.json()) as {idToken: string; localId: string};
  return {idToken: data.idToken, uid: data.localId};
}

async function seedPuzzle(letterKey: string, letters: string[], words: string[]): Promise<void> {
  await admin.firestore().collection("puzzles").doc(letterKey).set({
    tier: "medium", rackSize: letters.length, letters, letterKey, anchor: letterKey,
    answers: words.map((w) => ({word: w, length: w.length, definition: null})),
    answerCount: words.length, random: Math.random(),
  });
}

let friendSeq = 0;
async function makeFriends(a: {idToken: string; uid: string}, b: {idToken: string; uid: string}): Promise<void> {
  const n = friendSeq++;
  await request(app).post("/friends/request")
    .set(auth(a.idToken)).set("idempotency-key", `mefr${n}`).send({toUid: b.uid});
  await request(app).post("/friends/respond")
    .set(auth(b.idToken)).set("idempotency-key", `mere${n}`).send({fromUid: a.uid, accept: true});
}

describe("GET /me/matches/active settles stale matches", () => {
  test("an active match whose endsAt passed is finalized and dropped from the active list", async () => {
    await seedPuzzle("AERT", ["A", "E", "R", "T"], ["TEAR", "RATE", "ATE"]);
    await seedPuzzle("AEST", ["A", "E", "S", "T"], ["EATS", "SEAT", "TEA"]);
    await seedPuzzle("AELS", ["A", "E", "L", "S"], ["SEAL", "ALES", "SEA"]);
    const a = await mintUser();
    const b = await mintUser();
    await makeFriends(a, b);
    const ch = await request(app).post("/matches/challenge")
      .set(auth(a.idToken)).set("idempotency-key", "me-1").send({toUid: b.uid, settings: {mode: "async"}});
    const matchId = ch.body.matchId as string;
    await request(app).post(`/matches/${matchId}/respond`).set(auth(b.idToken)).send({accept: true});

    // Simulate the 6h async deadline having already passed.
    await admin.firestore().collection("matches").doc(matchId).update({endsAt: Date.now() - 1000});

    const list = await request(app).get("/me/matches/active").set(auth(b.idToken));
    expect(list.status).toBe(200);
    const mine = (list.body.matches as {matchId: string}[]).find((x) => x.matchId === matchId);
    expect(mine).toBeUndefined();

    const m = (await admin.firestore().collection("matches").doc(matchId).get()).data() as
      {status: string; winner: string | null};
    expect(m.status).toBe("finished");
    expect(m.winner).toBeDefined();
  });

  test("a still-live active match remains in the active list", async () => {
    await seedPuzzle("AERT", ["A", "E", "R", "T"], ["TEAR", "RATE", "ATE"]);
    await seedPuzzle("AEST", ["A", "E", "S", "T"], ["EATS", "SEAT", "TEA"]);
    await seedPuzzle("AELS", ["A", "E", "L", "S"], ["SEAL", "ALES", "SEA"]);
    const a = await mintUser();
    const b = await mintUser();
    await makeFriends(a, b);
    const ch = await request(app).post("/matches/challenge")
      .set(auth(a.idToken)).set("idempotency-key", "me-2").send({toUid: b.uid, settings: {mode: "async"}});
    const matchId = ch.body.matchId as string;
    await request(app).post(`/matches/${matchId}/respond`).set(auth(b.idToken)).send({accept: true});

    const list = await request(app).get("/me/matches/active").set(auth(b.idToken));
    expect(list.status).toBe(200);
    const mine = (list.body.matches as {matchId: string}[]).find((x) => x.matchId === matchId);
    expect(mine).toBeTruthy();

    const m = (await admin.firestore().collection("matches").doc(matchId).get()).data() as {status: string};
    expect(m.status).toBe("active");
  });
});

describe("respondChallenge always sets a deadline (regression)", () => {
  test("accept sets status active, startedAt > 0, and endsAt = startedAt + kAsyncRoundMs", async () => {
    await seedPuzzle("AERT", ["A", "E", "R", "T"], ["TEAR", "RATE", "ATE"]);
    await seedPuzzle("AEST", ["A", "E", "S", "T"], ["EATS", "SEAT", "TEA"]);
    await seedPuzzle("AELS", ["A", "E", "L", "S"], ["SEAL", "ALES", "SEA"]);
    const a = await mintUser();
    const b = await mintUser();
    await makeFriends(a, b);
    const ch = await request(app).post("/matches/challenge")
      .set(auth(a.idToken)).set("idempotency-key", "me-3").send({toUid: b.uid, settings: {mode: "async"}});
    const matchId = ch.body.matchId as string;

    const resp = await request(app).post(`/matches/${matchId}/respond`)
      .set(auth(b.idToken)).send({accept: true});
    expect(resp.status).toBe(200);
    expect(resp.body.status).toBe("active");

    const m = (await admin.firestore().collection("matches").doc(matchId).get()).data() as
      {status: string; startedAt: number; endsAt: number};
    expect(m.status).toBe("active");
    expect(m.startedAt).toBeGreaterThan(0);
    expect(m.endsAt).toBe(m.startedAt + kAsyncRoundMs);
  });
});
