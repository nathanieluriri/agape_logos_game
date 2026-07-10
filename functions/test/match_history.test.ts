// NOTE: the plan named this file matches.test.ts, but plan 11 already owns
// functions/test/matches.test.ts (the match-flow emulator suite), so the
// history-read suite lives here instead.
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

async function seedMatch(uid: string, matchId: string, endedAt: number, result: string): Promise<void> {
  await admin.firestore().collection("users").doc(uid).collection("matchHistory").doc(matchId).set({
    matchId,
    opponentUid: "opp",
    opponentName: "Rival",
    result,
    score: 12,
    opponentScore: 9,
    endedAt,
    settings: {difficulty: "medium", durationSec: 120},
  });
}

describe("GET /me/matches", () => {
  test("empty by default", async () => {
    const {idToken} = await mintUser();
    const res = await request(app).get("/me/matches").set("Authorization", `Bearer ${idToken}`);
    expect(res.status).toBe(200);
    expect(res.body.history).toEqual([]);
  });

  test("returns the caller's history newest-first", async () => {
    const {idToken, uid} = await mintUser();
    await seedMatch(uid, "m1", 1000, "loss");
    await seedMatch(uid, "m2", 3000, "win");
    await seedMatch(uid, "m3", 2000, "draw");
    const res = await request(app).get("/me/matches").set("Authorization", `Bearer ${idToken}`);
    expect(res.status).toBe(200);
    expect(res.body.history.map((h: {matchId: string}) => h.matchId)).toEqual(["m2", "m3", "m1"]);
    expect(res.body.history[0].result).toBe("win");
    expect(res.body.history[0].opponentName).toBe("Rival");
  });

  test("401 without auth", async () => {
    const res = await request(app).get("/me/matches");
    expect(res.status).toBe(401);
  });
});
