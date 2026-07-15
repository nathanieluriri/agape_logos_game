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

async function seedPuzzle(letterKey: string, letters: string[], words: string[]): Promise<void> {
  await admin.firestore().collection("puzzles").doc(letterKey).set({
    tier: "medium", rackSize: letters.length, letters, letterKey, anchor: letterKey,
    answers: words.map((w) => ({word: w, length: w.length, definition: null})),
    answerCount: words.length, random: Math.random(),
  });
}
async function setInventory(uid: string, inv: Record<string, number>): Promise<void> {
  await admin.firestore().collection("users").doc(uid).set({inventory: inv}, {merge: true});
}
async function rackWord(matchId: string, uid: string): Promise<string> {
  const rack = (await admin.firestore().collection("matches").doc(matchId)
    .collection("racks").doc(uid).get()).data() as {letterKey: string};
  const puzzle = (await admin.firestore().collection("puzzles").doc(rack.letterKey).get())
    .data() as {answers: {word: string}[]};
  return puzzle.answers[0].word;
}
// Force the match into a playable window without waiting on the countdown.
async function forceActive(matchId: string): Promise<void> {
  const now = Date.now();
  await admin.firestore().collection("matches").doc(matchId)
    .update({status: "active", startedAt: now - 1000, endsAt: now + 60000});
}

describe("matches", () => {
  test("create -> lobby + code + creator rack; 401 without auth", async () => {
    expect((await request(app).post("/matches").set("idempotency-key", "n").send({})).status).toBe(401);
    await seedPuzzle("AERT", ["A", "E", "R", "T"], ["TEAR", "RATE", "ATE"]);
    await seedPuzzle("AEST", ["A", "E", "S", "T"], ["EATS", "SEAT", "TEA"]);
    await seedPuzzle("AELS", ["A", "E", "L", "S"], ["SEAL", "ALES", "SEA"]);
    const {idToken, uid} = await mintUser();
    const res = await request(app).post("/matches")
      .set("Authorization", `Bearer ${idToken}`).set("idempotency-key", "c1")
      .send({settings: {difficulty: "medium", durationSec: 120}});
    expect(res.status).toBe(201);
    expect(res.body.matchId).toBeTruthy();
    expect(res.body.code).toMatch(/^[ABCDEFGHJKLMNPRSTUVWY]{4}$/);
    const rack = await admin.firestore().collection("matches").doc(res.body.matchId)
      .collection("racks").doc(uid).get();
    expect(rack.exists).toBe(true);
    expect((rack.data() as {answers: unknown[]}).answers.length).toBeGreaterThan(0);
    // creator rack answers are encrypted on the wire (length + enc only).
    expect((rack.data() as {answers: {enc: string}[]}).answers[0].enc).toBeTruthy();
  });

  test("create is idempotent per idempotency-key", async () => {
    const {idToken} = await mintUser();
    const post = () => request(app).post("/matches")
      .set("Authorization", `Bearer ${idToken}`).set("idempotency-key", "same").send({});
    const a = await post();
    const b = await post();
    expect(b.body.matchId).toBe(a.body.matchId);
    expect(b.body.code).toBe(a.body.code);
  });

  test("join by code adds the player with the SAME rack; unknown code 404", async () => {
    const creator = await mintUser();
    const joiner = await mintUser();
    const created = await request(app).post("/matches")
      .set("Authorization", `Bearer ${creator.idToken}`).set("idempotency-key", "j1").send({});
    // "ZZZZ" is MALFORMED, not merely unknown: Z is absent from the reduced
    // code alphabet (ABCDEFGHJKLMNPRSTUVWY), so schema validation rejects it.
    const malformed = await request(app).post("/matches/join")
      .set("Authorization", `Bearer ${joiner.idToken}`).send({code: "ZZZZ"});
    expect(malformed.status).toBe(400);
    // A well-formed code that was never reserved is a 404.
    const unknown = "BCDF" === created.body.code ? "BCDG" : "BCDF";
    const bad = await request(app).post("/matches/join")
      .set("Authorization", `Bearer ${joiner.idToken}`).send({code: unknown});
    expect(bad.status).toBe(404);
    const join = await request(app).post("/matches/join")
      .set("Authorization", `Bearer ${joiner.idToken}`).send({code: created.body.code});
    expect(join.status).toBe(200);
    const m = (await admin.firestore().collection("matches").doc(created.body.matchId).get()).data() as
      {participants: string[]; usedPuzzleIds: string[]; puzzleId: string};
    expect(m.participants).toContain(joiner.uid);
    expect(m.usedPuzzleIds).toEqual([m.puzzleId]); // one SHARED puzzle for both
  });

  test("submit: valid scores, invalid rejected, duplicate is idempotent", async () => {
    const creator = await mintUser();
    const joiner = await mintUser();
    const created = await request(app).post("/matches")
      .set("Authorization", `Bearer ${creator.idToken}`).set("idempotency-key", "s1").send({});
    await request(app).post("/matches/join")
      .set("Authorization", `Bearer ${joiner.idToken}`).send({code: created.body.code});
    await forceActive(created.body.matchId);

    const word = await rackWord(created.body.matchId, creator.uid);
    const ok = await request(app).post(`/matches/${created.body.matchId}/submit`)
      .set("Authorization", `Bearer ${creator.idToken}`).send({word});
    expect(ok.status).toBe(200);
    expect(ok.body.accepted).toBe(true);
    expect(ok.body.score).toBe(word.length);
    expect(ok.body.wordsFound).toBe(1);

    const dup = await request(app).post(`/matches/${created.body.matchId}/submit`)
      .set("Authorization", `Bearer ${creator.idToken}`).send({word});
    expect(dup.body.accepted).toBe(false);
    expect(dup.body.wordsFound).toBe(1); // not double-counted

    const bad = await request(app).post(`/matches/${created.body.matchId}/submit`)
      .set("Authorization", `Bearer ${creator.idToken}`).send({word: "ZZZZ"});
    expect(bad.body.accepted).toBe(false);
  });

  test("powerup: 402 without inventory; spends + writes an event when owned", async () => {
    const creator = await mintUser();
    const joiner = await mintUser();
    const created = await request(app).post("/matches")
      .set("Authorization", `Bearer ${creator.idToken}`).set("idempotency-key", "p1").send({});
    await request(app).post("/matches/join")
      .set("Authorization", `Bearer ${joiner.idToken}`).send({code: created.body.code});
    await forceActive(created.body.matchId);

    const broke = await request(app).post(`/matches/${created.body.matchId}/powerup`)
      .set("Authorization", `Bearer ${creator.idToken}`).set("idempotency-key", "e1")
      .send({kind: "fog_bank"});
    expect(broke.status).toBe(402);

    await setInventory(creator.uid, {fog: 1});
    const fired = await request(app).post(`/matches/${created.body.matchId}/powerup`)
      .set("Authorization", `Bearer ${creator.idToken}`).set("idempotency-key", "e2")
      .send({kind: "fog_bank"});
    expect(fired.status).toBe(200);
    const ev = (await admin.firestore().collection("matches").doc(created.body.matchId)
      .collection("events").doc("e2").get()).data() as
      {kind: string; targetUid: string; participants: string[]};
    expect(ev.kind).toBe("fog_bank");
    expect(ev.targetUid).toBe(joiner.uid);
    expect(ev.participants).toEqual(expect.arrayContaining([creator.uid, joiner.uid]));
    const inv = ((await admin.firestore().collection("users").doc(creator.uid).get())
      .data() as {inventory: Record<string, number>}).inventory;
    expect(inv.fog).toBe(0); // spent

    // replay by the same event id does not spend again
    const replay = await request(app).post(`/matches/${created.body.matchId}/powerup`)
      .set("Authorization", `Bearer ${creator.idToken}`).set("idempotency-key", "e2")
      .send({kind: "fog_bank"});
    expect(replay.body.reason).toBe("replay");
  });

  test("finalize (lazy) on expiry: winner by wordsFound + history for both", async () => {
    const creator = await mintUser();
    const joiner = await mintUser();
    const created = await request(app).post("/matches")
      .set("Authorization", `Bearer ${creator.idToken}`).set("idempotency-key", "f1").send({});
    await request(app).post("/matches/join")
      .set("Authorization", `Bearer ${joiner.idToken}`).send({code: created.body.code});
    await forceActive(created.body.matchId);
    const word = await rackWord(created.body.matchId, creator.uid);
    await request(app).post(`/matches/${created.body.matchId}/submit`)
      .set("Authorization", `Bearer ${creator.idToken}`).send({word}); // creator: 1 word

    // Expire the timer, then a GET triggers lazy finalize.
    await admin.firestore().collection("matches").doc(created.body.matchId)
      .update({endsAt: Date.now() - 1000});
    const done = await request(app).get(`/matches/${created.body.matchId}`)
      .set("Authorization", `Bearer ${creator.idToken}`);
    expect(done.body.status).toBe("finished");
    expect(done.body.winner).toBe(creator.uid); // 1 > 0

    const cHist = (await admin.firestore().collection("users").doc(creator.uid)
      .collection("matchHistory").doc(created.body.matchId).get()).data() as {result: string};
    const jHist = (await admin.firestore().collection("users").doc(joiner.uid)
      .collection("matchHistory").doc(created.body.matchId).get()).data() as {result: string};
    expect(cHist.result).toBe("win");
    expect(jHist.result).toBe("loss");
  });

  test("leave a lobby cancels it and frees the code", async () => {
    const {idToken} = await mintUser();
    const created = await request(app).post("/matches")
      .set("Authorization", `Bearer ${idToken}`).set("idempotency-key", "l1").send({});
    const left = await request(app).post(`/matches/${created.body.matchId}/leave`)
      .set("Authorization", `Bearer ${idToken}`).send({});
    expect(left.status).toBe(200);
    const codeDoc = (await admin.firestore().collection("matchCodes").doc(created.body.code).get())
      .data() as {active: boolean};
    expect(codeDoc.active).toBe(false);
    const joiner = await mintUser();
    const reJoin = await request(app).post("/matches/join")
      .set("Authorization", `Bearer ${joiner.idToken}`).send({code: created.body.code});
    expect(reJoin.status).toBe(404); // closed code
  });
});
