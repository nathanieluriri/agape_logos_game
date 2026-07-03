import {describe, test, expect} from "@jest/globals";
import {Puzzle, withDefinedAnswersOnly} from "../src/generation/puzzle";

const base: Puzzle = {
  tier: "easy",
  rackSize: 3,
  letters: ["W", "N", "O"],
  letterKey: "NOW",
  anchor: "NOW",
  answerCount: 4,
  genVersion: 1,
  answers: [
    {word: "NO", length: 2, definition: "not any"},
    {word: "ON", length: 2, definition: "in contact with"},
    {word: "WON", length: 3, definition: null},
    {word: "NOW", length: 3, definition: "at the present time"},
  ],
};

describe("withDefinedAnswersOnly", () => {
  test("drops undefined answers and recomputes answerCount", () => {
    const cleaned = withDefinedAnswersOnly(base, 3);
    expect(cleaned).not.toBeNull();
    expect(cleaned?.answers.map((a) => a.word)).toEqual(["NO", "ON", "NOW"]);
    expect(cleaned?.answerCount).toBe(3);
  });

  test("treats blank definitions as missing", () => {
    const p: Puzzle = {
      ...base,
      answers: [
        {word: "NO", length: 2, definition: "not any"},
        {word: "ON", length: 2, definition: "in contact with"},
        {word: "WON", length: 3, definition: "   "},
        {word: "NOW", length: 3, definition: "at the present time"},
      ],
    };
    expect(withDefinedAnswersOnly(p, 3)?.answers.map((a) => a.word)).toEqual([
      "NO",
      "ON",
      "NOW",
    ]);
  });

  test("returns the same puzzle when every answer is defined", () => {
    const p: Puzzle = {
      ...base,
      answers: base.answers.map((a) => ({...a, definition: a.definition ?? "x"})),
    };
    expect(withDefinedAnswersOnly(p, 3)).toBe(p);
  });

  test("returns null when too few defined answers remain", () => {
    const p: Puzzle = {
      ...base,
      answers: [
        {word: "NO", length: 2, definition: "not any"},
        {word: "ON", length: 2, definition: null},
        {word: "WON", length: 3, definition: null},
        {word: "NOW", length: 3, definition: null},
      ],
    };
    expect(withDefinedAnswersOnly(p, 3)).toBeNull();
  });
});
