import {describe, test, expect} from "@jest/globals";
import {sortLetters, buildAnagramIndex} from "../src/generation/anagram_index";

describe("sortLetters", () => {
  test("sorts letters ascending", () => {
    expect(sortLetters("NOW")).toBe("NOW");
    expect(sortLetters("WON")).toBe("NOW");
    expect(sortLetters("ON")).toBe("NO");
  });
});

describe("buildAnagramIndex", () => {
  test("groups anagrams under one sorted key", () => {
    const index = buildAnagramIndex(["ON", "NO", "WON", "NOW"]);
    expect(new Set(index.get("NO"))).toEqual(new Set(["ON", "NO"]));
    expect(new Set(index.get("NOW"))).toEqual(new Set(["WON", "NOW"]));
  });
  test("missing key returns undefined", () => {
    const index = buildAnagramIndex(["ON"]);
    expect(index.get("XYZ")).toBeUndefined();
  });
});
