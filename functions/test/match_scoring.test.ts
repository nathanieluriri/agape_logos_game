import {describe, test, expect} from "@jest/globals";
import {
  wordScore,
  computeWinner,
  POWERUP_ITEM_ID,
  POWERUP_DURATION_MS,
  DIFFICULTY_TIER,
} from "../src/services/match_scoring";

describe("wordScore", () => {
  test("is the word length", () => {
    expect(wordScore("TEAR")).toBe(4);
    expect(wordScore("AB")).toBe(2);
  });
});

describe("computeWinner", () => {
  const players = (a: number, b: number) => ({
    uidA: {wordsFound: a, score: a * 3},
    uidB: {wordsFound: b, score: b * 3},
  });
  test("more words wins", () => {
    expect(computeWinner(["uidA", "uidB"], players(5, 3))).toBe("uidA");
    expect(computeWinner(["uidA", "uidB"], players(2, 6))).toBe("uidB");
  });
  test("equal words, no timestamps, equal score is a draw", () => {
    expect(computeWinner(["uidA", "uidB"], players(4, 4))).toBe("draw");
  });
});

describe("powerup + tier maps", () => {
  test("kinds map to the store item ids they spend", () => {
    expect(POWERUP_ITEM_ID).toEqual({
      letter_freeze: "freeze_letter",
      fog_bank: "fog",
      scramble: "scramble",
      word_steal: "word_steal",
    });
  });
  test("durations match the contract (10s / 8s / instant / instant)", () => {
    expect(POWERUP_DURATION_MS.letter_freeze).toBe(10000);
    expect(POWERUP_DURATION_MS.fog_bank).toBe(8000);
    expect(POWERUP_DURATION_MS.scramble).toBe(0);
    expect(POWERUP_DURATION_MS.word_steal).toBe(0);
  });
  test("difficulty maps to a pool tier", () => {
    expect(DIFFICULTY_TIER).toEqual({easy: "easy", medium: "medium", hard: "hard"});
  });
});
