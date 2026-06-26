import {describe, test, expect} from "@jest/globals";
import {buildAnagramIndex} from "../src/generation/anagram_index";
import {letterKey, findAnswers} from "../src/generation/rack";

describe("letterKey", () => {
  test("canonicalizes a rack to sorted letters", () => {
    expect(letterKey(["W", "N", "O"])).toBe("NOW");
    expect(letterKey(["O", "N", "W"])).toBe("NOW");
  });
});

describe("findAnswers", () => {
  test("NOW rack yields ON, NO, WON, NOW and not obscure WO/OW", () => {
    // index built ONLY over common words, so WO/OW are absent by construction.
    const index = buildAnagramIndex(["ON", "NO", "WON", "NOW"]);
    expect(findAnswers(["W", "N", "O"], index)).toEqual(["NO", "ON", "NOW", "WON"]);
  });

  test("respects letter multiplicity", () => {
    // Rack A,T (one of each) cannot spell ATT.
    const index = buildAnagramIndex(["AT", "TA", "ATT"]);
    expect(findAnswers(["A", "T"], index)).toEqual(["AT", "TA"]);
  });

  test("duplicate-letter rack (EERIE) can spell words reusing a letter", () => {
    const index = buildAnagramIndex(["EERIE", "EYRIE", "EERIER"]);
    // EERIE = E,E,R,I,E ; EERIER needs two R, rack has one -> excluded.
    expect(findAnswers(["E", "E", "R", "I", "E"], index)).toEqual(["EERIE"]);
  });
});
