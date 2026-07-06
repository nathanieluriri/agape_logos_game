import {describe, test, expect} from "@jest/globals";
import * as fs from "fs";
import * as os from "os";
import * as path from "path";
import {loadBlocklist} from "../src/generation/profanity";
import {makeWordData} from "../src/generation/word_data";

describe("loadBlocklist", () => {
  test("ignores blanks and # comments, normalizes case", () => {
    const p = path.join(os.tmpdir(), `blocklist_${Date.now()}.txt`);
    fs.writeFileSync(p, "# comment\n\nDamn\nhell\n   \n");
    const set = loadBlocklist(p);
    fs.unlinkSync(p);
    expect(set.has("DAMN")).toBe(true);
    expect(set.has("HELL")).toBe(true);
    expect(set.size).toBe(2);
  });

  test("missing file yields an empty set", () => {
    const missing = path.join(os.tmpdir(), "no_such_blocklist_xyz.txt");
    expect(loadBlocklist(missing).size).toBe(0);
  });
});

describe("makeWordData blocklist + rank", () => {
  const valid = ["NOW", "WON", "OWN", "NO", "ON"];
  const freq = ["now", "won", "own", "no", "on"];

  test("excludes blocked words from valid and common", () => {
    const data = makeWordData(valid, freq, 50000, new Set(["WON"]));
    expect(data.isValid("WON")).toBe(false);
    expect(data.isCommon("WON")).toBe(false);
    expect(data.isValid("NOW")).toBe(true);
    expect(data.commonWords).not.toContain("WON");
    expect(data.commonWords).toContain("NOW");
  });

  test("rank reflects frequency order, Infinity beyond the set", () => {
    const data = makeWordData(valid, freq, 50000);
    expect(data.rank("NOW")).toBe(0);
    expect(data.rank("ON")).toBe(4);
    expect(data.rank("ZZZ")).toBe(Infinity);
  });
});
