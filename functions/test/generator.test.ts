import {describe, test, expect} from "@jest/globals";
import {makeWordData} from "../src/generation/word_data";
import {buildAnagramIndex} from "../src/generation/anagram_index";
import {mulberry32} from "../src/generation/random";
import {commonWordsOfLength, generateTierBatch, hasDistinctLetters} from "../src/generation/generator";

// Common 3-letter anchors and their sub-words.
const common = ["NOW", "ON", "NO", "WON", "ARE", "EAR", "ERA", "ARC", "CAR", "RAT", "ART", "TAR"];
const wordData = makeWordData(common, common, 50000);
const index = buildAnagramIndex(wordData.commonWords);

describe("commonWordsOfLength", () => {
  test("filters by exact length", () => {
    expect(commonWordsOfLength(wordData.commonWords, 3).sort()).toContain("NOW");
    expect(commonWordsOfLength(wordData.commonWords, 3)).not.toContain("ON");
  });
});

describe("generateTierBatch", () => {
  test("produces gated, deduped puzzles for the tier", () => {
    const res = generateTierBatch({
      tier: "easy",
      count: 2,
      wordData,
      index,
      existingKeys: new Set<string>(),
      rng: mulberry32(1),
    });
    expect(res.puzzles.length).toBe(2);
    for (const p of res.puzzles) {
      expect(p.tier).toBe("easy");
      expect(p.rackSize).toBe(3);
      expect(p.answerCount).toBeGreaterThanOrEqual(3); // easy gate
      expect(p.answers).toContain(p.anchor); // pangram present
    }
    // Deduped by letterKey.
    const keys = res.puzzles.map((p) => p.letterKey);
    expect(new Set(keys).size).toBe(keys.length);
  });

  test("skips anchors whose letterKey is already used", () => {
    const res = generateTierBatch({
      tier: "easy",
      count: 5,
      wordData,
      index,
      existingKeys: new Set<string>(["NOW"]), // exclude the N,O,W rack
      rng: mulberry32(1),
    });
    expect(res.puzzles.every((p) => p.letterKey !== "NOW")).toBe(true);
  });

  test("reports shortfall when candidates run out", () => {
    const res = generateTierBatch({
      tier: "easy",
      count: 999,
      wordData,
      index,
      existingKeys: new Set<string>(),
      rng: mulberry32(1),
    });
    expect(res.shortfall).toBe(999 - res.puzzles.length);
    expect(res.shortfall).toBeGreaterThan(0);
  });
});

describe("hasDistinctLetters", () => {
  test("true when all letters are unique", () => {
    expect(hasDistinctLetters("CAT")).toBe(true);
    expect(hasDistinctLetters("RATE")).toBe(true);
  });
  test("false for any repeated letter", () => {
    expect(hasDistinctLetters("BAA")).toBe(false);
    expect(hasDistinctLetters("LEVEL")).toBe(false);
    expect(hasDistinctLetters("EEE")).toBe(false);
  });
});

describe("generateTierBatch distinct-letter anchors", () => {
  test("every anchor and rack has unique letters", () => {
    const words = ["NOW", "WON", "ARE", "EAR", "ERA", "ARC", "CAR", "RAT", "ART", "TAR", "ODD"];
    const wd = makeWordData(words, words, 50000);
    const idx = buildAnagramIndex(wd.commonWords);
    const res = generateTierBatch({
      tier: "easy", count: 5, wordData: wd, index: idx,
      existingKeys: new Set<string>(), rng: mulberry32(7),
    });
    for (const p of res.puzzles) {
      expect(hasDistinctLetters(p.anchor)).toBe(true);
      expect(new Set(p.letters).size).toBe(p.letters.length);
    }
    expect(res.puzzles.map((p) => p.anchor)).not.toContain("ODD");
  });
});
