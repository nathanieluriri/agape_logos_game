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

interface DictionaryApiEntry {
  meanings?: {definitions?: {definition?: string}[]}[];
}

/**
 * Default fetcher hitting the free Dictionary API. 200 -> first definition;
 * 404 -> null (no entry); transient failure -> retry with backoff, then null.
 */
export function dictionaryApiFetch(maxRetries: number): FetchFn {
  return async (word: string): Promise<string | null> => {
    const url = `https://api.dictionaryapi.dev/api/v2/entries/en/${word.toLowerCase()}`;
    for (let attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        const res = await fetch(url);
        if (res.status === 404) return null;
        if (res.ok) {
          const data = (await res.json()) as DictionaryApiEntry[];
          const def = data?.[0]?.meanings?.[0]?.definitions?.[0]?.definition;
          return def ?? null;
        }
        // Non-ok, non-404 (e.g. 429/5xx): fall through to backoff.
      } catch {
        // Network error: fall through to backoff.
      }
      if (attempt < maxRetries) {
        await new Promise((r) => setTimeout(r, 250 * 2 ** attempt));
      }
    }
    return null;
  };
}
