import * as fs from "fs";

export function normalizeWord(raw: string): string | null {
  const w = raw.trim().toUpperCase();
  return /^[A-Z]+$/.test(w) ? w : null;
}

export interface WordData {
  isValid(word: string): boolean;
  isCommon(word: string): boolean;
  // 0-based frequency rank (lower = more frequent). Infinity for words beyond
  // the loaded common horizon or absent from the frequency list. Tiers filter
  // anchors and answers on this to control difficulty.
  rank(word: string): number;
  commonWords: string[];
}

/**
 * @param validWords      every legal word (validity list).
 * @param frequencyRanked words ordered most-frequent first.
 * @param cutoff          how many top-ranked frequency entries count as common.
 * @param blocklist       words to exclude entirely (anchors and answers).
 * @param isDefined       optional gate: when given, a word only counts as common
 *                        if it has a definition. This keeps the game's vocabulary
 *                        to words that can be defined, so every answer is defined
 *                        by construction and obscure undefined words never appear.
 */
export function makeWordData(
  validWords: string[],
  frequencyRanked: string[],
  cutoff: number,
  blocklist?: ReadonlySet<string>,
  isDefined?: (word: string) => boolean,
): WordData {
  const blocked = blocklist ?? new Set<string>();
  const valid = new Set<string>();
  for (const raw of validWords) {
    const w = normalizeWord(raw);
    if (w && !blocked.has(w)) valid.add(w);
  }

  const common = new Set<string>();
  const rankOf = new Map<string, number>();
  const limit = Math.min(cutoff, frequencyRanked.length);
  for (let i = 0; i < limit; i++) {
    const w = normalizeWord(frequencyRanked[i]);
    if (w && valid.has(w) && !common.has(w) && (!isDefined || isDefined(w))) {
      common.add(w);
      rankOf.set(w, i);
    }
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
    rank: (word) => {
      const w = normalizeWord(word);
      if (w === null) return Infinity;
      const r = rankOf.get(w);
      return r === undefined ? Infinity : r;
    },
    commonWords: [...common],
  };
}

export function loadWordDataFromFiles(
  validityPath: string,
  frequencyPath: string,
  cutoff: number,
  blocklist?: ReadonlySet<string>,
  isDefined?: (word: string) => boolean,
): WordData {
  const validWords = fs.readFileSync(validityPath, "utf8").split(/\r?\n/);
  // Frequency file lines are "word<TAB>count"; take the first token.
  const frequencyRanked = fs
    .readFileSync(frequencyPath, "utf8")
    .split(/\r?\n/)
    .map((line) => line.split(/\s+/)[0] ?? "");
  return makeWordData(validWords, frequencyRanked, cutoff, blocklist, isDefined);
}
