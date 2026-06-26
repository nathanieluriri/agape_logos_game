import {describe, test, expect, beforeEach} from "@jest/globals";
import * as admin from "firebase-admin";
import {Puzzle} from "../src/generation/puzzle";
import {
  writePuzzles,
  loadExistingLetterKeys,
  getStats,
  updateLibraryMeta,
} from "../src/pool/puzzle_pool";

function puzzle(letterKey: string, tier: Puzzle["tier"]): Puzzle {
  return {
    tier,
    rackSize: letterKey.length,
    letters: letterKey.split(""),
    letterKey,
    anchor: letterKey,
    answers: [{word: letterKey, length: letterKey.length, definition: null}],
    answerCount: 1,
    genVersion: 1,
  };
}

async function clearPuzzles(): Promise<void> {
  const db = admin.firestore();
  const snap = await db.collection("puzzles").get();
  await Promise.all(snap.docs.map((d) => d.ref.delete()));
}

describe("puzzle pool", () => {
  beforeEach(clearPuzzles);

  test("writes docs keyed by letterKey and is idempotent on re-run", async () => {
    await writePuzzles([puzzle("NOW", "easy"), puzzle("AERS", "medium")]);
    await writePuzzles([puzzle("NOW", "easy")]); // replay
    const keys = await loadExistingLetterKeys();
    expect(keys).toEqual(new Set(["NOW", "AERS"]));
  });

  test("getStats counts per tier and updateLibraryMeta persists them", async () => {
    await writePuzzles([
      puzzle("NOW", "easy"),
      puzzle("CAT", "easy"),
      puzzle("AERS", "medium"),
    ]);
    const stats = await getStats();
    expect(stats.total).toBe(3);
    expect(stats.perTier.easy).toBe(2);
    expect(stats.perTier.medium).toBe(1);

    await updateLibraryMeta(stats);
    const meta = await admin.firestore().doc("meta/puzzleLibrary").get();
    expect(meta.data()?.totalCount).toBe(3);
    expect(meta.data()?.perTier.easy).toBe(2);
  });
});
