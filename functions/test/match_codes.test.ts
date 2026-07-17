import {describe, test, expect} from "@jest/globals";
import {generateCode, kMatchCodeAlphabet, kMatchCodeLength} from "../src/services/match_codes";

describe("generateCode", () => {
  test("is kMatchCodeLength chars, all from the reduced alphabet", () => {
    const code = generateCode(() => 0.5);
    expect(code).toHaveLength(kMatchCodeLength);
    for (const ch of code) expect(kMatchCodeAlphabet.includes(ch)).toBe(true);
  });

  test("alphabet excludes the ambiguous letters I O Q X Z", () => {
    for (const ch of "IOQXZ") expect(kMatchCodeAlphabet.includes(ch)).toBe(false);
  });

  test("is deterministic for a fixed rng and maps 0 / near-1 to the ends", () => {
    expect(generateCode(() => 0)).toBe(kMatchCodeAlphabet[0].repeat(kMatchCodeLength));
    const last = kMatchCodeAlphabet[kMatchCodeAlphabet.length - 1];
    expect(generateCode(() => 0.999999)).toBe(last.repeat(kMatchCodeLength));
  });
});
