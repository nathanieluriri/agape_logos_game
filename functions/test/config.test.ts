import {describe, test, expect} from "@jest/globals";
import {TIERS, TIER_ORDER} from "../src/generation/config";

describe("tier config", () => {
  test("rack sizes increase by tier", () => {
    expect(TIER_ORDER.map((t) => TIERS[t].rackSize)).toEqual([3, 4, 5, 6]);
  });

  test("min answers per tier", () => {
    expect(TIER_ORDER.map((t) => TIERS[t].minAnswers)).toEqual([3, 3, 3, 3]);
  });

  test("every tier caps answers at 5", () => {
    expect(TIER_ORDER.map((t) => TIERS[t].maxAnswers)).toEqual([5, 5, 5, 5]);
  });

  test("answerCutoff never exceeds anchorCutoff", () => {
    for (const t of TIER_ORDER) {
      expect(TIERS[t].answerCutoff).toBeLessThanOrEqual(TIERS[t].anchorCutoff);
    }
  });

  test("pool targets sum to 1000", () => {
    const sum = TIER_ORDER.reduce((acc, t) => acc + TIERS[t].poolTarget, 0);
    expect(sum).toBe(1000);
  });
});
