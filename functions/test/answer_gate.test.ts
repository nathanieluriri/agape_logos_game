import {describe, test, expect} from "@jest/globals";
import {TierConfig} from "../src/generation/config";
import {meetsAnswerGate} from "../src/generation/quality";

const tier: TierConfig = {
  tier: "easy",
  rackSize: 3,
  minAnswers: 3,
  maxAnswers: 6,
  frequencyCutoff: 15000,
  poolTarget: 10,
};

describe("meetsAnswerGate with maxAnswers", () => {
  test("passes within [min, max]", () => {
    expect(meetsAnswerGate(3, tier)).toBe(true);
    expect(meetsAnswerGate(6, tier)).toBe(true);
  });

  test("rejects below min and above max", () => {
    expect(meetsAnswerGate(2, tier)).toBe(false);
    expect(meetsAnswerGate(7, tier)).toBe(false);
  });

  test("no upper bound when maxAnswers is unset", () => {
    const noMax: TierConfig = {...tier, maxAnswers: undefined};
    expect(meetsAnswerGate(999, noMax)).toBe(true);
  });
});
