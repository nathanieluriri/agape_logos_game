import {describe, test, expect} from "@jest/globals";
import {normalizeWord, makeWordData} from "../src/generation/word_data";

describe("normalizeWord", () => {
  test("uppercases and trims valid words", () => {
    expect(normalizeWord("  now ")).toBe("NOW");
  });
  test("rejects non-alphabetic", () => {
    expect(normalizeWord("ab1")).toBeNull();
    expect(normalizeWord("a-b")).toBeNull();
    expect(normalizeWord("")).toBeNull();
  });
});

describe("makeWordData", () => {
  // valid list includes obscure WO/OW; frequency list (common) does NOT.
  const valid = ["ON", "NO", "WON", "NOW", "WO", "OW"];
  const freqRanked = ["the", "now", "on", "no", "won"]; // most frequent first
  const data = makeWordData(valid, freqRanked, 50000);

  test("isValid covers the whole validity list", () => {
    expect(data.isValid("WO")).toBe(true);
    expect(data.isValid("now")).toBe(true); // case-insensitive
    expect(data.isValid("ZZZ")).toBe(false);
  });

  test("isCommon only for words in the frequency list AND valid", () => {
    expect(data.isCommon("NOW")).toBe(true);
    expect(data.isCommon("WO")).toBe(false); // valid but not in frequency list
    expect(data.isCommon("THE")).toBe(false); // frequent but not in validity list
  });

  test("commonWords is the uppercased intersection", () => {
    expect([...data.commonWords].sort()).toEqual(["NO", "NOW", "ON", "WON"]);
  });

  test("cutoff limits how many frequency entries count as common", () => {
    const tight = makeWordData(valid, freqRanked, 2); // only "the","now" considered
    expect(tight.isCommon("NOW")).toBe(true);
    expect(tight.isCommon("ON")).toBe(false); // beyond cutoff
  });
});
