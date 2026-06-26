import {describe, test, expect} from "@jest/globals";
import {RawPuzzle} from "../src/generation/generator";
import {attachDefinitions} from "../src/generation/puzzle";

const raw: RawPuzzle = {
  tier: "easy",
  rackSize: 3,
  letters: ["W", "N", "O"],
  letterKey: "NOW",
  anchor: "NOW",
  answers: ["NO", "ON", "WON", "NOW"],
  answerCount: 4,
};

describe("attachDefinitions", () => {
  test("maps each answer to its definition, null when missing", () => {
    const defs = new Map<string, string | null>([
      ["NO", "not any"],
      ["ON", "in contact with"],
      ["WON", null],
      // NOW intentionally absent from the map
    ]);
    const puzzle = attachDefinitions(raw, defs, 1);
    expect(puzzle.genVersion).toBe(1);
    expect(puzzle.answers).toEqual([
      {word: "NO", length: 2, definition: "not any"},
      {word: "ON", length: 2, definition: "in contact with"},
      {word: "WON", length: 3, definition: null},
      {word: "NOW", length: 3, definition: null},
    ]);
  });
});
