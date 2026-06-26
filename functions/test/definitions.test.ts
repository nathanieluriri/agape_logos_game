import {describe, test, expect} from "@jest/globals";
import * as fs from "fs";
import * as os from "os";
import * as path from "path";
import {
  loadDefinitionCache,
  saveDefinitionCache,
  resolveDefinitions,
  type DefinitionCache,
} from "../src/generation/definitions";

describe("definition cache file", () => {
  test("missing file loads as empty; round-trips through save/load", () => {
    const p = path.join(os.tmpdir(), `defcache_${Date.now()}.json`);
    expect(loadDefinitionCache(p)).toEqual({});
    saveDefinitionCache(p, {NO: "not any", WON: null});
    expect(loadDefinitionCache(p)).toEqual({NO: "not any", WON: null});
    fs.unlinkSync(p);
  });

  test("corrupt (non-JSON) cache file returns {} without throwing", () => {
    const p = path.join(os.tmpdir(), `defcache_corrupt_${Date.now()}.json`);
    fs.writeFileSync(p, "not valid json {{{{", "utf8");
    expect(() => loadDefinitionCache(p)).not.toThrow();
    expect(loadDefinitionCache(p)).toEqual({});
    fs.unlinkSync(p);
  });
});

describe("resolveDefinitions", () => {
  test("uses cache, fetches only misses, records nulls, caps concurrency", async () => {
    const cache: DefinitionCache = {NO: "not any"};
    const fetched: string[] = [];
    let inFlight = 0;
    let maxInFlight = 0;
    const fetchFn = async (word: string): Promise<string | null> => {
      inFlight++;
      maxInFlight = Math.max(maxInFlight, inFlight);
      await new Promise((r) => setTimeout(r, 5));
      inFlight--;
      fetched.push(word);
      return word === "ZZZ" ? null : `def:${word}`;
    };

    const result = await resolveDefinitions(["NO", "ON", "WON", "ZZZ"], cache, fetchFn, 2);

    expect(fetched.sort()).toEqual(["ON", "WON", "ZZZ"]); // NO came from cache
    expect(maxInFlight).toBeLessThanOrEqual(2);
    expect(result.get("NO")).toBe("not any");
    expect(result.get("ON")).toBe("def:ON");
    expect(result.get("ZZZ")).toBeNull();
    expect(cache.ON).toBe("def:ON"); // cache mutated with new results
  });
});
