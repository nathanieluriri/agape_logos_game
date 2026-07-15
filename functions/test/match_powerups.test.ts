import {describe, test, expect} from "@jest/globals";
import * as admin from "firebase-admin";
import request from "supertest";
import {createApp} from "../src/app";
import {settleMatch} from "../src/services/match_finalize";
import type {ActiveEffect, MatchData} from "../src/services/match_types";

jest.setTimeout(120000);
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

async function forceActive(matchId: string, endsInMs = 60000): Promise<void> {
  const now = Date.now();
  await admin.firestore().collection("matches").doc(matchId)
    .update({status: "active", startedAt: now - 1000, endsAt: now + endsInMs});
}

// Pins a player's rack to a known seeded puzzle so letters/answers are
// deterministic regardless of which pool puzzle the draw picked.
async function pinRack(
  matchId: string, uid: string, letterKey: string, letters: string[], answerCount: number,
): Promise<void> {
  await admin.firestore().collection("matches").doc(matchId).collection("racks").doc(uid)
    .set({letterKey, letters, foundWords: [], answerCount}, {merge: true});
}

async function readMatch(matchId: string): Promise<MatchData> {
  return (await admin.firestore().collection("matches").doc(matchId).get()).data() as MatchData;
}

async function readEffects(matchId: string, uid: string): Promise<ActiveEffect[]> {
  const m = await readMatch(matchId);
  return (m.activeEffects?.[uid] ?? []) as ActiveEffect[];
}

interface Duo {
  matchId: string;
  creator: {idToken: string; uid: string};
  joiner: {idToken: string; uid: string};
}

async function newActiveMatch(key: string): Promise<Duo> {
  const creator = await mintUser();
  const joiner = await mintUser();
  const created = await request(app).post("/matches")
    .set("Authorization", `Bearer ${creator.idToken}`).set("idempotency-key", `create-${key}`).send({});
  await request(app).post("/matches/join")
    .set("Authorization", `Bearer ${joiner.idToken}`).send({code: created.body.code});
  await forceActive(created.body.matchId);
  return {matchId: created.body.matchId, creator, joiner};
}

function fire(d: Duo, byToken: string, kind: string, eventId: string) {
  return request(app).post(`/matches/${d.matchId}/powerup`)
    .set("Authorization", `Bearer ${byToken}`).set("idempotency-key", eventId)
    .send({kind});
}

beforeAll(async () => {
  await seedPuzzle("AERT", ["A", "E", "R", "T"], ["TEAR", "RATE", "ATE"]);
});

describe("activeEffects: offensive powerups", () => {
  test("fog_bank writes an activeEffects entry on the target with expiresAt = now + 8000, plus an event", async () => {
    const d = await newActiveMatch("fog");
    await setInventory(d.creator.uid, {fog: 1});
    const before = Date.now();
    const res = await fire(d, d.creator.idToken, "fog_bank", "fx-fog-1");
    expect(res.status).toBe(200);
    expect(typeof res.body.serverNow).toBe("number");
    expect(res.body.serverNow).toBeGreaterThanOrEqual(before);

    const eff = await readEffects(d.matchId, d.joiner.uid);
    expect(eff.length).toBe(1);
    expect(eff[0].kind).toBe("fog_bank");
    expect(eff[0].byUid).toBe(d.creator.uid);
    expect(eff[0].expiresAt).toBeGreaterThanOrEqual(before + 8000);
    expect(eff[0].expiresAt).toBeLessThanOrEqual(Date.now() + 8000);

    const ev = (await admin.firestore().collection("matches").doc(d.matchId)
      .collection("events").doc("fx-fog-1").get()).data() as {kind: string};
    expect(ev.kind).toBe("fog_bank");
  });

  test("letter_freeze picks a letter CHARACTER present in the target rack", async () => {
    const d = await newActiveMatch("frz");
    await pinRack(d.matchId, d.joiner.uid, "AERT", ["A", "E", "R", "T"], 3);
    await setInventory(d.creator.uid, {freeze_letter: 1});
    const res = await fire(d, d.creator.idToken, "letter_freeze", "fx-frz-1");
    expect(res.status).toBe(200);

    const eff = await readEffects(d.matchId, d.joiner.uid);
    expect(eff.length).toBe(1);
    expect(eff[0].kind).toBe("letter_freeze");
    const letter = eff[0].payload.letter as string;
    expect(["A", "E", "R", "T"]).toContain(letter);

    const ev = (await admin.firestore().collection("matches").doc(d.matchId)
      .collection("events").doc("fx-frz-1").get()).data() as {payload: {letter: string}};
    expect(ev.payload.letter).toBe(letter);
  });
});

describe("shield blocks the next offensive powerup", () => {
  test("armed shield consumes itself, applies nothing, appends a blocked event, still spends the caster", async () => {
    const d = await newActiveMatch("shield-block");
    await pinRack(d.matchId, d.joiner.uid, "AERT", ["A", "E", "R", "T"], 3);
    await setInventory(d.joiner.uid, {shield: 1});
    await setInventory(d.creator.uid, {scramble: 1});

    const arm = await fire(d, d.joiner.idToken, "shield", "fx-shield-1");
    expect(arm.status).toBe(200);
    const armed = await readEffects(d.matchId, d.joiner.uid);
    expect(armed.some((e) => e.kind === "shield" && e.expiresAt === 0)).toBe(true);

    const res = await fire(d, d.creator.idToken, "scramble", "fx-scr-1");
    expect(res.status).toBe(200);
    expect(res.body.reason).toBe("blocked");

    // Shield consumed; nothing else landed on the target.
    const after = await readEffects(d.matchId, d.joiner.uid);
    expect(after.length).toBe(0);
    // Rack untouched (scramble was blocked).
    const rack = (await admin.firestore().collection("matches").doc(d.matchId)
      .collection("racks").doc(d.joiner.uid).get()).data() as {letters: string[]};
    expect(rack.letters).toEqual(["A", "E", "R", "T"]);
    // Blocked event with the original kind.
    const ev = (await admin.firestore().collection("matches").doc(d.matchId)
      .collection("events").doc("fx-scr-1").get()).data() as
      {kind: string; payload: {originalKind: string}};
    expect(ev.kind).toBe("blocked");
    expect(ev.payload.originalKind).toBe("scramble");
    // Caster still spent the item.
    const inv = ((await admin.firestore().collection("users").doc(d.creator.uid).get())
      .data() as {inventory: Record<string, number>}).inventory;
    expect(inv.scramble).toBe(0);
  });
});

describe("combo_lock wards word_steal", () => {
  test("word_steal against combo_lock returns ok:false reason warded; spends nothing; no event", async () => {
    const d = await newActiveMatch("ward");
    await pinRack(d.matchId, d.joiner.uid, "AERT", ["A", "E", "R", "T"], 3);
    // Give the target a stealable word so only the ward can be the reason.
    await admin.firestore().collection("matches").doc(d.matchId)
      .collection("racks").doc(d.joiner.uid).set({foundWords: ["ATE"]}, {merge: true});
    await setInventory(d.joiner.uid, {combo_lock: 1});
    await setInventory(d.creator.uid, {word_steal: 1});

    await fire(d, d.joiner.idToken, "combo_lock", "fx-lock-1");
    const res = await fire(d, d.creator.idToken, "word_steal", "fx-steal-1");
    expect(res.status).toBe(200);
    expect(res.body.ok).toBe(false);
    expect(res.body.reason).toBe("warded");
    expect(typeof res.body.serverNow).toBe("number");

    const inv = ((await admin.firestore().collection("users").doc(d.creator.uid).get())
      .data() as {inventory: Record<string, number>}).inventory;
    expect(inv.word_steal).toBe(1); // NOT spent
    const ev = await admin.firestore().collection("matches").doc(d.matchId)
      .collection("events").doc("fx-steal-1").get();
    expect(ev.exists).toBe(false); // nothing appended
  });
});

describe("defensive self-fires", () => {
  test("shield arms on the caster with expiresAt 0; a second shield 409s", async () => {
    const d = await newActiveMatch("shield-arm");
    await setInventory(d.creator.uid, {shield: 2});
    const res = await fire(d, d.creator.idToken, "shield", "fx-arm-1");
    expect(res.status).toBe(200);
    const eff = await readEffects(d.matchId, d.creator.uid);
    expect(eff.length).toBe(1);
    expect(eff[0]).toMatchObject({kind: "shield", byUid: d.creator.uid, expiresAt: 0});

    const again = await fire(d, d.creator.idToken, "shield", "fx-arm-2");
    expect(again.status).toBe(409);
    const inv = ((await admin.firestore().collection("users").doc(d.creator.uid).get())
      .data() as {inventory: Record<string, number>}).inventory;
    expect(inv.shield).toBe(1); // only the first fire spent
  });

  test("time_boost increments players.{caster}.endsAtBonusMs by 30000", async () => {
    const d = await newActiveMatch("boost");
    await setInventory(d.creator.uid, {time_boost: 1});
    const res = await fire(d, d.creator.idToken, "time_boost", "fx-boost-1");
    expect(res.status).toBe(200);
    const m = await readMatch(d.matchId);
    expect(m.players[d.creator.uid].endsAtBonusMs).toBe(30000);
  });

  test("double_points writes a 20s activeEffects entry on the caster", async () => {
    const d = await newActiveMatch("dp-arm");
    await setInventory(d.creator.uid, {double_points: 1});
    const before = Date.now();
    const res = await fire(d, d.creator.idToken, "double_points", "fx-dp-1");
    expect(res.status).toBe(200);
    const eff = await readEffects(d.matchId, d.creator.uid);
    expect(eff.length).toBe(1);
    expect(eff[0].kind).toBe("double_points");
    expect(eff[0].expiresAt).toBeGreaterThanOrEqual(before + 20000);
    expect(eff[0].expiresAt).toBeLessThanOrEqual(Date.now() + 20000);
  });
});

describe("submit under effects", () => {
  test("double_points window scores 2 * word.length; outside it, normal", async () => {
    const d = await newActiveMatch("dp-submit");
    await pinRack(d.matchId, d.creator.uid, "AERT", ["A", "E", "R", "T"], 3);
    await pinRack(d.matchId, d.joiner.uid, "AERT", ["A", "E", "R", "T"], 3);
    await setInventory(d.creator.uid, {double_points: 1});
    await fire(d, d.creator.idToken, "double_points", "fx-dp-2");

    const doubled = await request(app).post(`/matches/${d.matchId}/submit`)
      .set("Authorization", `Bearer ${d.creator.idToken}`).send({word: "TEAR"});
    expect(doubled.body.accepted).toBe(true);
    expect(doubled.body.score).toBe(8); // 2 * 4

    // The joiner has no effect: normal scoring.
    const normal = await request(app).post(`/matches/${d.matchId}/submit`)
      .set("Authorization", `Bearer ${d.joiner.idToken}`).send({word: "TEAR"});
    expect(normal.body.accepted).toBe(true);
    expect(normal.body.score).toBe(4);
  });

  test("a word containing the frozen letter is rejected with reason frozen during the window", async () => {
    const d = await newActiveMatch("frz-submit");
    await pinRack(d.matchId, d.creator.uid, "AERT", ["A", "E", "R", "T"], 3);
    await setInventory(d.joiner.uid, {freeze_letter: 1});
    await fire(d, d.joiner.idToken, "letter_freeze", "fx-frz-2");
    const eff = await readEffects(d.matchId, d.creator.uid);
    const letter = eff[0].payload.letter as string;
    // Every AERT answer contains T/E/A/R except ATE misses R; pick one with it.
    const hit = ["TEAR", "RATE", "ATE"].find((w) => w.includes(letter)) as string;

    const res = await request(app).post(`/matches/${d.matchId}/submit`)
      .set("Authorization", `Bearer ${d.creator.idToken}`).send({word: hit});
    expect(res.body.accepted).toBe(false);
    expect(res.body.reason).toBe("frozen");
  });

  test("submit is accepted between endsAt and endsAt + myBonus", async () => {
    const d = await newActiveMatch("boost-submit");
    await pinRack(d.matchId, d.creator.uid, "AERT", ["A", "E", "R", "T"], 3);
    const now = Date.now();
    await admin.firestore().collection("matches").doc(d.matchId).update({
      endsAt: now - 1000,
      [`players.${d.creator.uid}.endsAtBonusMs`]: 60000,
    });
    const res = await request(app).post(`/matches/${d.matchId}/submit`)
      .set("Authorization", `Bearer ${d.creator.idToken}`).send({word: "TEAR"});
    expect(res.body.accepted).toBe(true);
  });
});

describe("time_boost-aware settling", () => {
  test("settleMatch does NOT finalize until endsAt + max(bonus) passes", async () => {
    const d = await newActiveMatch("settle-boost");
    const now = Date.now();
    await admin.firestore().collection("matches").doc(d.matchId).update({
      endsAt: now - 1000,
      [`players.${d.creator.uid}.endsAtBonusMs`]: 60000,
    });
    const still = await settleMatch(d.matchId);
    expect(still?.status).toBe("active");

    await admin.firestore().collection("matches").doc(d.matchId).update({endsAt: now - 70000});
    const done = await settleMatch(d.matchId);
    expect(done?.status).toBe("finished");
  });
});

describe("expired effect pruning", () => {
  test("expired activeEffects entries are pruned by the next firePowerup", async () => {
    const d = await newActiveMatch("prune");
    const stale: ActiveEffect = {
      kind: "double_points", byUid: d.creator.uid,
      startedAt: Date.now() - 30000, expiresAt: Date.now() - 10000, payload: {},
    };
    await admin.firestore().collection("matches").doc(d.matchId)
      .update({[`activeEffects.${d.creator.uid}`]: [stale]});
    await setInventory(d.creator.uid, {fog: 1});
    await fire(d, d.creator.idToken, "fog_bank", "fx-prune-1");
    const eff = await readEffects(d.matchId, d.creator.uid);
    expect(eff.length).toBe(0);
  });
});

describe("serverNow", () => {
  test("GET /matches/:id includes serverNow", async () => {
    const d = await newActiveMatch("srvnow");
    const res = await request(app).get(`/matches/${d.matchId}`)
      .set("Authorization", `Bearer ${d.creator.idToken}`);
    expect(res.status).toBe(200);
    expect(typeof res.body.serverNow).toBe("number");
    expect(Math.abs(res.body.serverNow - Date.now())).toBeLessThan(15000);
  });
});
