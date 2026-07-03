import {describe, test, expect} from "@jest/globals";
import * as admin from "firebase-admin";
import request from "supertest";
import {createApp} from "../src/app";
import {POWERUP_POOL} from "../src/rewards/config";
import {claimPowerup} from "../src/services/rewards_service";

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

const doc = (uid: string) => admin.firestore().collection("users").doc(uid);
const setLevel = (uid: string, level: number) => doc(uid).set({highestLevel: level}, {merge: true});
const agoTimestamp = (ms: number) => admin.firestore.Timestamp.fromMillis(Date.now() - ms);

describe("rewards", () => {
  test("locked below the minimum level", async () => {
    const {idToken} = await mintUser();
    const auth = `Bearer ${idToken}`;
    const status = await request(app).get("/rewards").set("Authorization", auth);
    expect(status.status).toBe(200);
    expect(status.body.unlocked).toBe(false);
    expect(status.body.coins.claimable).toBe(false);

    const claim = await request(app).post("/rewards/claim-coins").set("Authorization", auth);
    expect(claim.status).toBe(403);
    expect(claim.body.minLevel).toBe(status.body.minLevel);
  });

  test("401 without auth", async () => {
    expect((await request(app).get("/rewards")).status).toBe(401);
    expect((await request(app).post("/rewards/claim-coins")).status).toBe(401);
    expect((await request(app).post("/rewards/claim-powerup")).status).toBe(401);
  });

  test("coins: claim once, then cooldown, then claimable again after 72h", async () => {
    const {idToken, uid} = await mintUser();
    const auth = `Bearer ${idToken}`;
    await setLevel(uid, 5);

    const first = await request(app).post("/rewards/claim-coins").set("Authorization", auth);
    expect(first.status).toBe(200);
    expect(first.body.claimed).toBe(400);
    expect(first.body.coins).toBe(400);

    // Immediate replay -> on cooldown, no double-grant.
    const second = await request(app).post("/rewards/claim-coins").set("Authorization", auth);
    expect(second.status).toBe(409);
    expect(second.body.nextClaimInMs).toBeGreaterThan(0);
    const me = await request(app).get("/me").set("Authorization", auth);
    expect(me.body.coins).toBe(400); // still one grant

    // Simulate 73h passing -> claimable again.
    await doc(uid).set({rewards: {coinClaimAt: agoTimestamp(73 * 60 * 60 * 1000)}}, {merge: true});
    const third = await request(app).post("/rewards/claim-coins").set("Authorization", auth);
    expect(third.status).toBe(200);
    expect(third.body.coins).toBe(800);
  });

  test("does not stockpile: waiting longer still grants a single 400", async () => {
    const {idToken, uid} = await mintUser();
    const auth = `Bearer ${idToken}`;
    await setLevel(uid, 5);
    // Last claim was 10 days ago; only one claim is available, not several.
    await doc(uid).set(
      {coins: 0, rewards: {coinClaimAt: agoTimestamp(10 * 24 * 60 * 60 * 1000)}},
      {merge: true},
    );
    const first = await request(app).post("/rewards/claim-coins").set("Authorization", auth);
    expect(first.body.coins).toBe(400);
    const second = await request(app).post("/rewards/claim-coins").set("Authorization", auth);
    expect(second.status).toBe(409); // immediately back on cooldown
  });

  test("weekly powerup grants one from the pool and then goes on cooldown", async () => {
    const {idToken, uid} = await mintUser();
    const auth = `Bearer ${idToken}`;
    await setLevel(uid, 5);

    const res = await request(app).post("/rewards/claim-powerup").set("Authorization", auth);
    expect(res.status).toBe(200);
    expect(POWERUP_POOL).toContain(res.body.granted);
    expect(res.body.inventory[res.body.granted]).toBe(1);

    const status = await request(app).get("/rewards").set("Authorization", auth);
    expect(status.body.powerup.claimable).toBe(false);
    expect(status.body.powerup.nextClaimInMs).toBeGreaterThan(0);

    const again = await request(app).post("/rewards/claim-powerup").set("Authorization", auth);
    expect(again.status).toBe(409);
  });

  test("shuffle bag: no repeat until the pool is exhausted, no adjacent repeat", async () => {
    const {uid} = await mintUser();
    await setLevel(uid, 5);

    // Deterministic RNG so the property is reproducible.
    let seed = 987654321;
    const rng = () => {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      return seed / 0x7fffffff;
    };

    const granted: string[] = [];
    for (let i = 0; i < POWERUP_POOL.length * 2; i++) {
      // Clear only the cooldown; the bag + last-id persist to drive the cycle.
      await doc(uid).set({rewards: {powerupClaimAt: null}}, {merge: true});
      const r = await claimPowerup(uid, rng);
      expect(r.ok).toBe(true);
      if (r.ok) granted.push(r.granted);
    }

    // First full cycle covers every powerup exactly once.
    const cycle1 = granted.slice(0, POWERUP_POOL.length);
    expect(new Set(cycle1).size).toBe(POWERUP_POOL.length);
    expect([...cycle1].sort()).toEqual([...POWERUP_POOL].sort());

    // Second cycle likewise covers the whole pool.
    const cycle2 = granted.slice(POWERUP_POOL.length);
    expect(new Set(cycle2).size).toBe(POWERUP_POOL.length);

    // Never the same powerup twice in a row (including across the boundary).
    for (let i = 1; i < granted.length; i++) {
      expect(granted[i]).not.toBe(granted[i - 1]);
    }
  });
});
