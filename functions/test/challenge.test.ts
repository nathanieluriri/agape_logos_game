import {describe, test, expect} from "@jest/globals";
import * as admin from "firebase-admin";
import request from "supertest";
import {createApp} from "../src/app";
import {hasOpenMatchWith} from "../src/services/challenge_service";

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
    .set(auth(a.idToken)).set("idempotency-key", `cfr${n}`).send({toUid: b.uid});
  await request(app).post("/friends/respond")
    .set(auth(b.idToken)).set("idempotency-key", `cre${n}`).send({fromUid: a.uid, accept: true});
}

async function rackKey(matchId: string, uid: string): Promise<string> {
  const rack = (await admin.firestore().collection("matches").doc(matchId)
    .collection("racks").doc(uid).get()).data() as {letterKey: string};
  return rack.letterKey;
}

// --- pure: the one-open-challenge-per-pair guard (no emulator) -------------
describe("hasOpenMatchWith (pure)", () => {
  test("blocks a second challenge to the same friend while one is open", () => {
    const open = [{participants: ["me", "bob"], status: "active"}];
    expect(hasOpenMatchWith(open as never, "me", "bob")).toBe(true);
    expect(hasOpenMatchWith(open as never, "me", "carol")).toBe(false);
  });
  test("a finished match does not block a new challenge", () => {
    expect(hasOpenMatchWith(
      [{participants: ["me", "bob"], status: "finished"}] as never, "me", "bob")).toBe(false);
  });
  test("lobby and countdown also count as open", () => {
    expect(hasOpenMatchWith([{participants: ["me", "bob"], status: "lobby"}] as never, "me", "bob")).toBe(true);
    expect(hasOpenMatchWith([{participants: ["me", "bob"], status: "countdown"}] as never, "me", "bob")).toBe(true);
    expect(hasOpenMatchWith([{participants: ["me", "bob"], status: "cancelled"}] as never, "me", "bob")).toBe(false);
  });
});

// --- emulator-backed challenge flow ---------------------------------------
describe("challenges", () => {
  test("challenge between non-friends is rejected (404 not_friends)", async () => {
    const a = await mintUser();
    const b = await mintUser();
    const res = await request(app).post("/matches/challenge")
      .set(auth(a.idToken)).set("idempotency-key", "ch-nf").send({toUid: b.uid});
    expect(res.status).toBe(404);
    expect(res.body.error).toBe("not_friends");
  });

  test("a second challenge to the same friend is 409 already_challenged", async () => {
    await seedPuzzle("AERT", ["A", "E", "R", "T"], ["TEAR", "RATE", "ATE"]);
    await seedPuzzle("AEST", ["A", "E", "S", "T"], ["EATS", "SEAT", "TEA"]);
    await seedPuzzle("AELS", ["A", "E", "L", "S"], ["SEAL", "ALES", "SEA"]);
    const a = await mintUser();
    const b = await mintUser();
    await makeFriends(a, b);
    const first = await request(app).post("/matches/challenge")
      .set(auth(a.idToken)).set("idempotency-key", "ch-1a").send({toUid: b.uid});
    expect(first.status).toBe(201);
    expect(first.body.matchId).toBeTruthy();
    const second = await request(app).post("/matches/challenge")
      .set(auth(a.idToken)).set("idempotency-key", "ch-1b").send({toUid: b.uid});
    expect(second.status).toBe(409);
    expect(second.body.error).toBe("already_challenged");
  });

  test("accept (async) goes active with a ~6h deadline and the SAME puzzle", async () => {
    await seedPuzzle("AERT", ["A", "E", "R", "T"], ["TEAR", "RATE", "ATE"]);
    await seedPuzzle("AEST", ["A", "E", "S", "T"], ["EATS", "SEAT", "TEA"]);
    await seedPuzzle("AELS", ["A", "E", "L", "S"], ["SEAL", "ALES", "SEA"]);
    const a = await mintUser();
    const b = await mintUser();
    await makeFriends(a, b);
    const ch = await request(app).post("/matches/challenge")
      .set(auth(a.idToken)).set("idempotency-key", "ch-2").send({toUid: b.uid, settings: {mode: "async"}});
    expect(ch.status).toBe(201);
    const matchId = ch.body.matchId as string;

    const resp = await request(app).post(`/matches/${matchId}/respond`)
      .set(auth(b.idToken)).send({accept: true});
    expect(resp.status).toBe(200);
    expect(resp.body.status).toBe("active");

    const m = (await admin.firestore().collection("matches").doc(matchId).get()).data() as
      {status: string; startedAt: number; endsAt: number; participants: string[]};
    expect(m.status).toBe("active");
    expect(m.participants).toEqual(expect.arrayContaining([a.uid, b.uid]));
    const sixHours = 6 * 60 * 60 * 1000;
    expect(m.endsAt - m.startedAt).toBe(sixHours);
    expect(m.endsAt).toBeGreaterThan(Date.now() + sixHours - 60000);

    // The invite doc is cleared once answered.
    const invite = await admin.firestore().collection("users").doc(b.uid)
      .collection("challenges").doc(matchId).get();
    expect(invite.exists).toBe(false);

    // Both players hold a rack built from the SAME shared puzzle (fair race).
    const [ka, kb] = await Promise.all([rackKey(matchId, a.uid), rackKey(matchId, b.uid)]);
    expect(ka).toBeTruthy();
    expect(kb).toBeTruthy();
    expect(ka).toBe(kb);
  });

  test("decline cancels the match and clears the invite", async () => {
    await seedPuzzle("AERT", ["A", "E", "R", "T"], ["TEAR", "RATE", "ATE"]);
    const a = await mintUser();
    const b = await mintUser();
    await makeFriends(a, b);
    const ch = await request(app).post("/matches/challenge")
      .set(auth(a.idToken)).set("idempotency-key", "ch-3").send({toUid: b.uid, settings: {mode: "async"}});
    const matchId = ch.body.matchId as string;

    const resp = await request(app).post(`/matches/${matchId}/respond`)
      .set(auth(b.idToken)).send({accept: false});
    expect(resp.status).toBe(200);
    expect(resp.body.status).toBe("cancelled");

    const m = (await admin.firestore().collection("matches").doc(matchId).get()).data() as {status: string};
    expect(m.status).toBe("cancelled");
    const invite = await admin.firestore().collection("users").doc(b.uid)
      .collection("challenges").doc(matchId).get();
    expect(invite.exists).toBe(false);

    // A finished/cancelled match no longer blocks a fresh challenge.
    const again = await request(app).post("/matches/challenge")
      .set(auth(a.idToken)).set("idempotency-key", "ch-3b").send({toUid: b.uid});
    expect(again.status).toBe(201);
  });

  test("replaying accept after it already succeeded is one-shot: no_challenge, deadline unchanged", async () => {
    await seedPuzzle("AERT", ["A", "E", "R", "T"], ["TEAR", "RATE", "ATE"]);
    await seedPuzzle("AEST", ["A", "E", "S", "T"], ["EATS", "SEAT", "TEA"]);
    await seedPuzzle("AELS", ["A", "E", "L", "S"], ["SEAL", "ALES", "SEA"]);
    const a = await mintUser();
    const b = await mintUser();
    await makeFriends(a, b);
    const ch = await request(app).post("/matches/challenge")
      .set(auth(a.idToken)).set("idempotency-key", "ch-5").send({toUid: b.uid, settings: {mode: "async"}});
    const matchId = ch.body.matchId as string;

    const first = await request(app).post(`/matches/${matchId}/respond`)
      .set(auth(b.idToken)).send({accept: true});
    expect(first.status).toBe(200);
    expect(first.body.status).toBe("active");
    const afterFirst = (await admin.firestore().collection("matches").doc(matchId).get()).data() as
      {status: string; startedAt: number; endsAt: number};

    // Simulate hours passing, then replay the exact same accept request.
    const replay = await request(app).post(`/matches/${matchId}/respond`)
      .set(auth(b.idToken)).send({accept: true});
    expect(replay.status).toBe(404);
    expect(replay.body.error).toBe("no_challenge");

    // The 6h deadline must NOT have been reset by the replay.
    const afterReplay = (await admin.firestore().collection("matches").doc(matchId).get()).data() as
      {status: string; startedAt: number; endsAt: number};
    expect(afterReplay.status).toBe("active");
    expect(afterReplay.startedAt).toBe(afterFirst.startedAt);
    expect(afterReplay.endsAt).toBe(afterFirst.endsAt);
  });

  test("replaying with decline after accept does not cancel the live match", async () => {
    await seedPuzzle("AERT", ["A", "E", "R", "T"], ["TEAR", "RATE", "ATE"]);
    await seedPuzzle("AEST", ["A", "E", "S", "T"], ["EATS", "SEAT", "TEA"]);
    await seedPuzzle("AELS", ["A", "E", "L", "S"], ["SEAL", "ALES", "SEA"]);
    const a = await mintUser();
    const b = await mintUser();
    await makeFriends(a, b);
    const ch = await request(app).post("/matches/challenge")
      .set(auth(a.idToken)).set("idempotency-key", "ch-6").send({toUid: b.uid, settings: {mode: "async"}});
    const matchId = ch.body.matchId as string;

    const accept = await request(app).post(`/matches/${matchId}/respond`)
      .set(auth(b.idToken)).send({accept: true});
    expect(accept.status).toBe(200);

    const declineReplay = await request(app).post(`/matches/${matchId}/respond`)
      .set(auth(b.idToken)).send({accept: false});
    expect(declineReplay.status).toBe(404);
    expect(declineReplay.body.error).toBe("no_challenge");

    const m = (await admin.firestore().collection("matches").doc(matchId).get()).data() as {status: string};
    expect(m.status).toBe("active");
  });

  test("respond from a non-invitee (challenger or a third party) is no_challenge", async () => {
    await seedPuzzle("AERT", ["A", "E", "R", "T"], ["TEAR", "RATE", "ATE"]);
    const a = await mintUser();
    const b = await mintUser();
    const c = await mintUser();
    await makeFriends(a, b);
    const ch = await request(app).post("/matches/challenge")
      .set(auth(a.idToken)).set("idempotency-key", "ch-7").send({toUid: b.uid, settings: {mode: "async"}});
    const matchId = ch.body.matchId as string;

    const byChallenger = await request(app).post(`/matches/${matchId}/respond`)
      .set(auth(a.idToken)).send({accept: true});
    expect(byChallenger.status).toBe(404);
    expect(byChallenger.body.error).toBe("no_challenge");

    const byThirdParty = await request(app).post(`/matches/${matchId}/respond`)
      .set(auth(c.idToken)).send({accept: true});
    expect(byThirdParty.status).toBe(404);
    expect(byThirdParty.body.error).toBe("no_challenge");

    // The real invitee can still answer; the guard didn't consume the challenge.
    const real = await request(app).post(`/matches/${matchId}/respond`)
      .set(auth(b.idToken)).send({accept: true});
    expect(real.status).toBe(200);
  });

  test("GET /me/matches/active lists an accepted async match", async () => {
    await seedPuzzle("AERT", ["A", "E", "R", "T"], ["TEAR", "RATE", "ATE"]);
    const a = await mintUser();
    const b = await mintUser();
    await makeFriends(a, b);
    const ch = await request(app).post("/matches/challenge")
      .set(auth(a.idToken)).set("idempotency-key", "ch-4").send({toUid: b.uid, settings: {mode: "async"}});
    const matchId = ch.body.matchId as string;
    await request(app).post(`/matches/${matchId}/respond`).set(auth(b.idToken)).send({accept: true});

    const list = await request(app).get("/me/matches/active").set(auth(b.idToken));
    expect(list.status).toBe(200);
    const mine = (list.body.matches as {matchId: string; mode: string; opponentUid: string}[])
      .find((x) => x.matchId === matchId);
    expect(mine).toBeTruthy();
    expect(mine?.mode).toBe("async");
    expect(mine?.opponentUid).toBe(a.uid);
  });
});
