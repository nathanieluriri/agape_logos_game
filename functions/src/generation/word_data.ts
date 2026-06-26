import * as fs from "fs";

export function normalizeWord(raw: string): string | null {
  const w = raw.trim().toUpperCase();
  return /^[A-Z]+$/.test(w) ? w : null;
}

export interface WordData {
  isValid(word: string): boolean;
  isCommon(word: string): boolean;
  commonWords: string[];
}

/**
 * @param validWords      every legal word (validity list).
 * @param frequencyRanked words ordered most-frequent first.
 * @param cutoff          how many top-ranked frequency entries count as common.
 */
export function makeWordData(
  validWords: string[],
  frequencyRanked: string[],
  cutoff: number,
): WordData {
  const valid = new Set<string>();
  for (const raw of validWords) {
    const w = normalizeWord(raw);
    if (w) valid.add(w);
  }

  const common = new Set<string>();
  const limit = Math.min(cutoff, frequencyRanked.length);
  for (let i = 0; i < limit; i++) {
    const w = normalizeWord(frequencyRanked[i]);
    if (w && valid.has(w)) common.add(w);
  }

  return {
    isValid: (word) => {
      const w = normalizeWord(word);
      return w !== null && valid.has(w);
    },
    isCommon: (word) => {
      const w = normalizeWord(word);
      return w !== null && common.has(w);
    },
    commonWords: [...common],
  };
}

export function loadWordDataFromFiles(
  validityPath: string,
  frequencyPath: string,
  cutoff: number,
): WordData {
  const validWords = fs.readFileSync(validityPath, "utf8").split(/\r?\n/);
  // Frequency file lines are "word<TAB>count"; take the first token.
  const frequencyRanked = fs
    .readFileSync(frequencyPath, "utf8")
    .split(/\r?\n/)
    .map((line) => line.split(/\s+/)[0] ?? "");
  return makeWordData(validWords, frequencyRanked, cutoff);
}
