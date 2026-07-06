import {describe, test, expect, beforeEach} from "@jest/globals";
import * as admin from "firebase-admin";
import {purgeUserPuzzleState} from "../src/scripts/purge_user_puzzle_state";

jest.setTimeout(90000);

describe("purgeUserPuzzleState", () => {
  beforeEach(async () => {
    const db = admin.firestore();
    const users = await db.collection("users").get();
    await Promise.all(users.docs.map((d) => d.ref.delete()));
  });

  test("clears assignments + draws but keeps profile and results", async () => {
    const db = admin.firestore();
    const u = db.collection("users").doc("u1");
    await u.set({coins: 500, highestLevel: 7});
    await u.collection("assignments").doc("ACT").set({completed: false});
    await u.collection("draws").doc("d1").set({at: 1});
    await u.collection("puzzleResults").doc("r1").set({score: 5});

    const res = await purgeUserPuzzleState();
    expect(res.assignments).toBe(1);
    expect(res.draws).toBe(1);
    expect((await u.collection("assignments").get()).size).toBe(0);
    expect((await u.collection("draws").get()).size).toBe(0);
    // Progression + history untouched.
    expect((await u.collection("puzzleResults").get()).size).toBe(1);
    expect((await u.get()).data()?.coins).toBe(500);
  });
});
