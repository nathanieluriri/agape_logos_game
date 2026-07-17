import {describe, test, expect} from "@jest/globals";
import {buildStarterPack} from "../src/scripts/export_starter_pack";

const pool = [
  {tier: "easy", rackSize: 3, letters: ["C", "A", "T"], anchor: "CAT", answerCount: 2,
    answers: [{word: "CAT", length: 3, definition: "a feline"}, {word: "ACT", length: 3, definition: "a deed"}]},
  {tier: "easy", rackSize: 3, letters: ["R", "A", "T"], anchor: "RAT", answerCount: 2,
    answers: [{word: "RAT", length: 3, definition: "a rodent"}, {word: "ART", length: 3, definition: "creative work"}]},
  {tier: "medium", rackSize: 4, letters: ["D", "O", "G", "S"], anchor: "DOGS", answerCount: 2,
    answers: [{word: "DOG", length: 3, definition: "an animal"}, {word: "DOGS", length: 4, definition: "more than one dog"}]},
];

describe("buildStarterPack", () => {
  test("emits client-shaped puzzles with starter ids, per tier", () => {
    const pack = buildStarterPack(pool, 1);
    expect(pack.version).toBeGreaterThan(0);
    expect(pack.puzzles).toHaveLength(2); // 1 easy + 1 medium
    const easy = pack.puzzles.find((p) => p.tier === "easy")!;
    expect(easy.letterKey).toMatch(/^starter-easy-\d+$/);
    expect(easy.answers[0]).toHaveProperty("definition");
    expect(easy.answers.every((a) => (a.definition ?? "").length > 0)).toBe(true);
  });
});
