import {describe, test, expect} from "@jest/globals";
import {mulberry32} from "../src/generation/random";
import {selectUnseen} from "../src/services/select_unseen";

describe("selectUnseen", () => {
  const ids = ["A", "B", "C", "D", "E"];

  test("excludes already-assigned ids", () => {
    const res = selectUnseen(ids, new Set(["A", "B"]), 2, mulberry32(1));
    expect(res.chosen).toHaveLength(2);
    expect(res.chosen).not.toContain("A");
    expect(res.chosen).not.toContain("B");
    expect(res.shortfall).toBe(0);
  });

  test("reports shortfall when not enough unseen", () => {
    const res = selectUnseen(ids, new Set(["A", "B", "C", "D"]), 3, mulberry32(1));
    expect(res.chosen).toEqual(["E"]);
    expect(res.shortfall).toBe(2);
  });

  test("never returns more than n and is deterministic for a seed", () => {
    const a = selectUnseen(ids, new Set(), 3, mulberry32(42));
    const b = selectUnseen(ids, new Set(), 3, mulberry32(42));
    expect(a.chosen).toHaveLength(3);
    expect(a.chosen).toEqual(b.chosen);
  });

  test("empty candidates yields empty chosen and full shortfall", () => {
    const res = selectUnseen([], new Set(), 4, mulberry32(1));
    expect(res.chosen).toEqual([]);
    expect(res.shortfall).toBe(4);
  });
});
