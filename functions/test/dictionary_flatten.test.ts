import {describe, it, expect} from "@jest/globals";
import {flattenDictionary} from "../src/services/dictionary_service";
import {PuzzleDoc} from "../src/services/assignment_service";

const mk = (
  tier: string,
  key: string,
  answers: {word: string; length: number; definition: string | null}[],
): PuzzleDoc => ({
  tier,
  rackSize: key.length,
  letters: key.split(""),
  letterKey: key,
  anchor: key,
  answers,
  answerCount: answers.length,
});

describe("flattenDictionary", () => {
  it("flattens answers and dedupes by word (case-insensitive), first wins", () => {
    const puzzles = [
      mk("easy", "ABC", [
        {word: "cab", length: 3, definition: "a taxi"},
        {word: "abc", length: 3, definition: null},
      ]),
      mk("medium", "XYZ", [
        {word: "CAB", length: 3, definition: "a duplicate, dropped"},
        {word: "zip", length: 3, definition: "fasten"},
      ]),
    ];
    const out = flattenDictionary(puzzles, 100);
    expect(out.map((e) => e.word.toUpperCase())).toEqual(["ABC", "CAB", "ZIP"]);
    // First occurrence of CAB (from the easy puzzle) keeps its definition + tier.
    const cab = out.find((e) => e.word.toUpperCase() === "CAB");
    expect(cab?.definition).toBe("a taxi");
    expect(cab?.tier).toBe("easy");
    expect(cab?.puzzleId).toBe("ABC");
  });

  it("respects the cap", () => {
    const puzzles = [
      mk("easy", "AAA", [
        {word: "a", length: 1, definition: null},
        {word: "b", length: 1, definition: null},
        {word: "c", length: 1, definition: null},
      ]),
    ];
    expect(flattenDictionary(puzzles, 2)).toHaveLength(2);
  });

  it("returns an empty list for no puzzles", () => {
    expect(flattenDictionary([], 100)).toEqual([]);
  });
});
