import * as fs from "fs";

export type FetchFn = (word: string) => Promise<string | null>;

export interface DefinitionCache {
  [word: string]: string | null;
}

export function loadDefinitionCache(path: string): DefinitionCache {
  try {
    return JSON.parse(fs.readFileSync(path, "utf8")) as DefinitionCache;
  } catch {
    return {};
  }
}

export function saveDefinitionCache(path: string, cache: DefinitionCache): void {
  fs.writeFileSync(path, JSON.stringify(cache, null, 0));
}

/**
 * Resolve definitions for `words`, cache-first. Misses are fetched through
 * `fetchFn` with at most `concurrency` requests in flight. New results are
 * written back into `cache` (the caller persists it afterwards).
 */
export async function resolveDefinitions(
  words: string[],
  cache: DefinitionCache,
  fetchFn: FetchFn,
  concurrency: number,
): Promise<Map<string, string | null>> {
  const result = new Map<string, string | null>();
  const misses: string[] = [];
  for (const word of words) {
    if (Object.prototype.hasOwnProperty.call(cache, word)) {
      result.set(word, cache[word]);
    } else if (!result.has(word)) {
      misses.push(word);
    }
  }

  let next = 0;
  async function worker(): Promise<void> {
    while (next < misses.length) {
      const word = misses[next++];
      const def = await fetchFn(word);
      cache[word] = def;
      result.set(word, def);
    }
  }
  const workers = Array.from(
    {length: Math.min(concurrency, misses.length)},
    () => worker(),
  );
  await Promise.all(workers);
  return result;
}

// Offline, in-memory definition source backed by a bundled word -> definition
// map (WordNet glosses, pre-built by scripts/build_dictionary.ts) plus an
// optional supplement (common function/irregular words WordNet omits). Loaded
// once into a Map for fast lookups; no network, fully deterministic.
let dictInstance: Map<string, string> | null = null;

function loadDict(dictPath: string, supplementPath: string): Map<string, string> {
  if (dictInstance) return dictInstance;
  const dict = new Map<string, string>();
  const base = JSON.parse(fs.readFileSync(dictPath, "utf8")) as Record<string, string>;
  for (const [w, d] of Object.entries(base)) dict.set(w.toUpperCase(), d);
  try {
    const sup = JSON.parse(fs.readFileSync(supplementPath, "utf8")) as Record<string, string>;
    for (const [w, d] of Object.entries(sup)) dict.set(w.toUpperCase(), d);
  } catch {
    // The supplement file is optional.
  }
  dictInstance = dict;
  return dict;
}

// Cheap regular de-inflection: maps a surface form to base-lemma candidates so
// plurals, verb forms, comparatives and adverbs resolve to their base word
// (CATS -> CAT, RUNNING -> RUN, BIGGER -> BIG, QUICKLY -> QUICK). Direct hits are
// tried first, so false candidates simply miss; irregular forms (GREW, SLEPT,
// MICE) come from the supplement instead.
function deinflect(w: string): string[] {
  const c: string[] = [];
  const add = (s: string): void => {
    if (s.length >= 2) c.push(s);
  };
  // Undouble a trailing doubled consonant (RUNN -> RUN, STOPP -> STOP).
  const undouble = (s: string): void => {
    if (s.length >= 3 && s[s.length - 1] === s[s.length - 2] && !"AEIOU".includes(s[s.length - 1])) {
      add(s.slice(0, -1));
    }
  };
  // Plurals and third-person singular.
  if (w.length > 4 && (w.endsWith("IES") || w.endsWith("IED"))) add(w.slice(0, -3) + "Y");
  if (w.length > 4 && /(SS|X|Z|CH|SH)ES$/.test(w)) add(w.slice(0, -2)); // boxes -> box
  if (w.length > 3 && w.endsWith("ES")) {
    add(w.slice(0, -2));
    add(w.slice(0, -1));
  }
  if (w.length > 2 && w.endsWith("S")) add(w.slice(0, -1));
  if (w.length > 4 && w.endsWith("MEN")) add(w.slice(0, -2) + "AN"); // firemen -> fireman
  // Past tense / past participle.
  if (w.length > 3 && w.endsWith("ED")) {
    add(w.slice(0, -2)); // walked -> walk
    add(w.slice(0, -1)); // liked -> like
    undouble(w.slice(0, -2)); // stopped -> stop
  }
  // Gerund / present participle.
  if (w.length > 4 && w.endsWith("ING")) {
    add(w.slice(0, -3)); // walking -> walk
    add(w.slice(0, -3) + "E"); // making -> make
    undouble(w.slice(0, -3)); // running -> run
  }
  // Adverbs and comparatives / superlatives.
  if (w.length > 4 && w.endsWith("LY")) {
    add(w.slice(0, -2)); // quickly -> quick
    add(w.slice(0, -2) + "E"); // nicely -> nice
  }
  if (w.length > 4 && w.endsWith("EST")) {
    add(w.slice(0, -3));
    add(w.slice(0, -2)); // largest -> large
    undouble(w.slice(0, -3)); // biggest -> big
  }
  if (w.length > 3 && w.endsWith("ER")) {
    add(w.slice(0, -2));
    add(w.slice(0, -1)); // larger -> large
    undouble(w.slice(0, -2)); // bigger -> big
  }
  return c;
}

export interface LocalDictionary {
  // Synchronous lookup: direct hit, then de-inflection fallback; null if absent.
  define(word: string): string | null;
}

// Loads the bundled dictionary once and exposes a synchronous lookup. Used both
// to define answers and to filter the common-word vocabulary down to words that
// actually have a definition (so every answer is defined by construction).
export function loadLocalDictionary(
  dictPath: string,
  supplementPath: string,
): LocalDictionary {
  const dict = loadDict(dictPath, supplementPath);
  return {
    define(word: string): string | null {
      const W = word.toUpperCase();
      const direct = dict.get(W);
      if (direct) return direct;
      for (const cand of deinflect(W)) {
        const d = dict.get(cand);
        if (d) return d;
      }
      return null;
    },
  };
}

// FetchFn adapter over the local dictionary for resolveDefinitions.
export function localDictionaryFetch(dictPath: string, supplementPath: string): FetchFn {
  const dict = loadLocalDictionary(dictPath, supplementPath);
  return async (word: string): Promise<string | null> => dict.define(word);
}
