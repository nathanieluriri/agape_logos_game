import {describe, test, expect, beforeEach} from "@jest/globals";
import * as admin from "firebase-admin";
import {purgePool} from "../src/scripts/purge_pool";

jest.setTimeout(90000);

describe("purgePool", () => {
  beforeEach(async () => {
    const db = admin.firestore();
    const existing = await db.collection("puzzles").get();
    await Promise.all(existing.docs.map((d) => d.ref.delete()));
  });

  test("deletes every puzzle doc and the library meta", async () => {
    const db = admin.firestore();
    await db.collection("puzzles").doc("ACT").set({tier: "easy"});
    await db.collection("puzzles").doc("AER").set({tier: "easy"});
    await db.doc("meta/puzzleLibrary").set({totalCount: 2});

    const res = await purgePool();
    expect(res.deleted).toBe(2);
    expect((await db.collection("puzzles").get()).size).toBe(0);
    expect((await db.doc("meta/puzzleLibrary").get()).exists).toBe(false);
  });
});
