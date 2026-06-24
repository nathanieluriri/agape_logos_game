import {describe, test, expect} from "@jest/globals";
import {TIERS, TIER_ORDER} from "../src/generation/config";

describe("tier config", () => {
  test("rack sizes increase by tier", () => {
    expect(TIERS.easy.rackSize).toBe(3);
    expect(TIERS.medium.rackSize).toBe(4);
    expect(TIERS.hard.rackSize).toBe(5);
    expect(TIERS.expert.rackSize).toBe(6);
  });

  test("min answers per tier", () => {
    expect(
      TIER_ORDER.map((t) => TIERS[t].minAnswers),
    ).toEqual([3, 5, 7, 9]);
  });

  test("pool targets sum to 1000", () => {
    const sum = TIER_ORDER.reduce((acc, t) => acc + TIERS[t].poolTarget, 0);
    expect(sum).toBe(1000);
  });
});
