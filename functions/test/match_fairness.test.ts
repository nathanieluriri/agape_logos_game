import {describe, test, expect} from "@jest/globals";
import * as admin from "firebase-admin";
import request from "supertest";
import {createApp} from "../src/app";
import {computeWinner} from "../src/services/match_scoring";
import {settleMatch} from "../src/services/match_finalize";

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

async function forceActive(matchId: string): Promise<void> {
  const now = Date.now();
  await admin.firestore().collection("matches").doc(matchId)
    .update({status: "active", startedAt: now - 1000, endsAt: now + 60000});
}

describe("same-puzzle fairness", () => {
  test("joiner gets the SAME letterKey rack as the creator; usedPuzzleIds stays single-entry", async () => {
    await seedPuzzle("AERT", ["A", "E", "R", "T"], ["TEAR", "RATE", "ATE"]);
    await seedPuzzle("AEST", ["A", "E", "S", "T"], ["EATS", "SEAT", "TEA"]);
    const creator = await mintUser();
    const joiner = await mintUser();
    const created = await request(app).post("/matches")
      .set("Authorization", `Bearer ${creator.idToken}`).set("idempotency-key", "fair1").send({});
    await request(app).post("/matches/join")
      .set("Authorization", `Bearer ${joiner.idToken}`).send({code: created.body.code});

    const creatorRack = (await admin.firestore().collection("matches").doc(created.body.matchId)
      .collection("racks").doc(creator.uid).get()).data() as {letterKey: string};
    const joinerRack = (await admin.firestore().collection("matches").doc(created.body.matchId)
      .collection("racks").doc(joiner.uid).get()).data() as {letterKey: string};
    expect(joinerRack.letterKey).toBe(creatorRack.letterKey);

    const m = (await admin.firestore().collection("matches").doc(created.body.matchId).get())
      .data() as {usedPuzzleIds: string[]; puzzleId: string};
    expect(m.usedPuzzleIds.length).toBe(1);
    expect(m.puzzleId).toBe(creatorRack.letterKey);
  });
});

describe("computeWinner tiebreak by lastWordAt then score", () => {
  test("more words wins outright", () => {
    const players = {
      uidA: {wordsFound: 5, score: 15},
      uidB: {wordsFound: 3, score: 30},
    };
    expect(computeWinner(["uidA", "uidB"], players)).toBe("uidA");
  });
  test("equal words: earlier lastWordAt wins", () => {
    const players = {
      uidA: {wordsFound: 4, score: 12, lastWordAt: 1000},
      uidB: {wordsFound: 4, score: 12, lastWordAt: 2000},
    };
    expect(computeWinner(["uidA", "uidB"], players)).toBe("uidA");
  });
  test("equal words and lastWordAt: higher score wins", () => {
    const players = {
      uidA: {wordsFound: 4, score: 16, lastWordAt: 1000},
      uidB: {wordsFound: 4, score: 12, lastWordAt: 1000},
    };
    expect(computeWinner(["uidA", "uidB"], players)).toBe("uidA");
  });
  test("equal everything: draw", () => {
    const players = {
      uidA: {wordsFound: 4, score: 12, lastWordAt: 1000},
      uidB: {wordsFound: 4, score: 12, lastWordAt: 1000},
    };
    expect(computeWinner(["uidA", "uidB"], players)).toBe("draw");
  });
  test("missing lastWordAt on both (legacy data): falls through to score/draw", () => {
    const players = {
      uidA: {wordsFound: 4, score: 12},
      uidB: {wordsFound: 4, score: 12},
    };
    expect(computeWinner(["uidA", "uidB"], players)).toBe("draw");
  });
});

describe("submitWord stamps lastWordAt / finishedAt", () => {
  test("accepted submit stamps lastWordAt; the last answer also stamps finishedAt", async () => {
    await seedPuzzle("FISH", ["F", "I", "S", "H"], ["FISH", "HIS"]);
    const creator = await mintUser();
    const joiner = await mintUser();
    const created = await request(app).post("/matches")
      .set("Authorization", `Bearer ${creator.idToken}`).set("idempotency-key", "stamp1").send({});
    await request(app).post("/matches/join")
      .set("Authorization", `Bearer ${joiner.idToken}`).send({code: created.body.code});
    await forceActive(created.body.matchId);

    const rack = (await admin.firestore().collection("matches").doc(created.body.matchId)
      .collection("racks").doc(creator.uid).get()).data() as {letterKey: string};
    const puzzle = (await admin.firestore().collection("puzzles").doc(rack.letterKey).get())
      .data() as {answers: {word: string}[]};
    const words = puzzle.answers.map((a) => a.word);

    const readPlayer = async () =>
      ((await admin.firestore().collection("matches").doc(created.body.matchId).get())
        .data() as {players: Record<string, {lastWordAt?: number; finishedAt?: number}>})
        .players[creator.uid];

    await request(app).post(`/matches/${created.body.matchId}/submit`)
      .set("Authorization", `Bearer ${creator.idToken}`).send({word: words[0]});
    let me = await readPlayer();
    expect(me.lastWordAt).toBeGreaterThan(0);
    if (words.length > 1) expect(me.finishedAt).toBeUndefined();

    for (const w of words.slice(1)) {
      await request(app).post(`/matches/${created.body.matchId}/submit`)
        .set("Authorization", `Bearer ${creator.idToken}`).send({word: w});
    }
    me = await readPlayer();
    expect(me.finishedAt).toBeGreaterThan(0);
  });
});

describe("settleMatch finalizes early once every participant has finishedAt", () => {
  test("finalizes an active match before endsAt when both players are done", async () => {
    await seedPuzzle("PEN", ["P", "E", "N"], ["PEN"]);
    const creator = await mintUser();
    const joiner = await mintUser();
    const created = await request(app).post("/matches")
      .set("Authorization", `Bearer ${creator.idToken}`).set("idempotency-key", "early1").send({});
    await request(app).post("/matches/join")
      .set("Authorization", `Bearer ${joiner.idToken}`).send({code: created.body.code});
    await forceActive(created.body.matchId);

    const rack = (await admin.firestore().collection("matches").doc(created.body.matchId)
      .collection("racks").doc(creator.uid).get()).data() as {letterKey: string};
    const puzzle = (await admin.firestore().collection("puzzles").doc(rack.letterKey).get())
      .data() as {answers: {word: string}[]};
    for (const a of puzzle.answers) {
      await request(app).post(`/matches/${created.body.matchId}/submit`)
        .set("Authorization", `Bearer ${creator.idToken}`).send({word: a.word});
      await request(app).post(`/matches/${created.body.matchId}/submit`)
        .set("Authorization", `Bearer ${joiner.idToken}`).send({word: a.word});
    }

    const settled = await settleMatch(created.body.matchId);
    expect(settled?.status).toBe("finished");
  });
});
