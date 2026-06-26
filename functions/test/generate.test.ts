import {describe, test, expect, beforeEach} from "@jest/globals";
import * as admin from "firebase-admin";
import * as os from "os";
import * as path from "path";
import {makeWordData} from "../src/generation/word_data";
import {buildAnagramIndex} from "../src/generation/anagram_index";
import {mulberry32} from "../src/generation/random";
import {loadExistingLetterKeys} from "../src/pool/puzzle_pool";
import {runGeneration, GenerateDeps} from "../src/scripts/generate";

const common = ["NOW", "ON", "NO", "WON", "CAT", "ACT", "CAR", "ARC", "RAT", "TAR", "ART"];

function deps(): GenerateDeps {
  const wordData = makeWordData(common, common, 50000);
  return {
    wordData,
    index: buildAnagramIndex(wordData.commonWords),
    fetchFn: async (w: string) => `def:${w}`,
    cache: {},
    cachePath: path.join(os.tmpdir(), `gen_cache_${Date.now()}.json`),
    concurrency: 2,
    genVersion: 1,
    rng: mulberry32(123),
  };
}

async function clearPuzzles(): Promise<void> {
  const db = admin.firestore();
  const snap = await db.collection("puzzles").get();
  await Promise.all(snap.docs.map((d) => d.ref.delete()));
}

describe("runGeneration", () => {
  beforeEach(clearPuzzles);

  test("writes gated puzzles with definitions and reports per tier", async () => {
    const report = await runGeneration([{tier: "easy", count: 2}], deps());
    expect(report.written).toBeGreaterThanOrEqual(1);
    const keys = await loadExistingLetterKeys();
    expect(keys.size).toBe(report.written);
    const doc = await admin.firestore().collection("puzzles").doc([...keys][0]).get();
    expect(doc.data()?.answers[0].definition).toMatch(/^def:/);
  });

  test("re-running does not duplicate existing letterKeys", async () => {
    await runGeneration([{tier: "easy", count: 2}], deps());
    const first = (await loadExistingLetterKeys()).size;
    await runGeneration([{tier: "easy", count: 2}], deps());
    const second = (await loadExistingLetterKeys()).size;
    expect(second).toBe(first); // dedupe against existing pool
  });
});
