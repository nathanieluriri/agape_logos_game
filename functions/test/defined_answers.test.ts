import {describe, test, expect} from "@jest/globals";
import {Puzzle, requireAllDefined} from "../src/generation/puzzle";

function puzzle(answers: {word: string; definition: string | null}[]): Puzzle {
  return {
    tier: "easy", rackSize: 3, letters: ["C", "A", "T"], letterKey: "ACT",
    anchor: "CAT", genVersion: 3, answerCount: answers.length,
    answers: answers.map((a) => ({word: a.word, length: a.word.length, definition: a.definition})),
  };
}

describe("requireAllDefined", () => {
  test("returns the puzzle unchanged when every answer is defined", () => {
    const p = puzzle([
      {word: "CAT", definition: "a feline"},
      {word: "ACT", definition: "a deed"},
      {word: "AT", definition: "toward"},
    ]);
    expect(requireAllDefined(p)).toBe(p);
  });

  test("returns null when any answer has no definition", () => {
    const p = puzzle([
      {word: "CAT", definition: "a feline"},
      {word: "ACT", definition: null},
    ]);
    expect(requireAllDefined(p)).toBeNull();
  });

  test("returns null when any definition is blank", () => {
    const p = puzzle([
      {word: "CAT", definition: "a feline"},
      {word: "ACT", definition: "   "},
    ]);
    expect(requireAllDefined(p)).toBeNull();
  });
});
