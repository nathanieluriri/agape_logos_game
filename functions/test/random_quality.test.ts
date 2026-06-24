import {describe, test, expect} from "@jest/globals";
import {mulberry32, shuffle} from "../src/generation/random";
import {meetsAnswerGate} from "../src/generation/quality";
import {TIERS} from "../src/generation/config";

describe("mulberry32 + shuffle", () => {
  test("same seed is deterministic", () => {
    const a = shuffle([1, 2, 3, 4, 5], mulberry32(42));
    const b = shuffle([1, 2, 3, 4, 5], mulberry32(42));
    expect(a).toEqual(b);
  });
  test("does not mutate the input and preserves elements", () => {
    const input = [1, 2, 3];
    const out = shuffle(input, mulberry32(7));
    expect(input).toEqual([1, 2, 3]);
    expect([...out].sort()).toEqual([1, 2, 3]);
  });
});

describe("meetsAnswerGate", () => {
  test("passes at or above the tier minimum", () => {
    expect(meetsAnswerGate(3, TIERS.easy)).toBe(true);
    expect(meetsAnswerGate(2, TIERS.easy)).toBe(false);
    expect(meetsAnswerGate(9, TIERS.expert)).toBe(true);
    expect(meetsAnswerGate(8, TIERS.expert)).toBe(false);
  });
});
