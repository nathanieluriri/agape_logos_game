import {describe, test, expect} from "@jest/globals";
import {loadBlocklist} from "../src/generation/profanity";
import {makeWordData} from "../src/generation/word_data";
import {BLOCKLIST_FILE} from "../src/generation/config";

describe("shipped blocklist", () => {
  const set = loadBlocklist(BLOCKLIST_FILE);

  test("covers representative offensive terms (exact-word, uppercase)", () => {
    for (const w of ["FUCK", "SHIT", "CUNT", "NIGGER", "FAGGOT", "RAPE", "WHORE"]) {
      expect(set.has(w)).toBe(true);
    }
  });

  test("does not over-block clean words", () => {
    for (const w of ["GRASS", "ASSESS", "PASS", "SCUNTHORPE", "SHIITAKE"]) {
      expect(set.has(w)).toBe(false);
    }
  });

  test("blocked words are removed from valid/common word data", () => {
    const wd = makeWordData(["CAT", "FUCK"], ["cat", "fuck"], 50000, set);
    expect(wd.isValid("FUCK")).toBe(false);
    expect(wd.isValid("CAT")).toBe(true);
    expect(wd.commonWords).not.toContain("FUCK");
  });
});
