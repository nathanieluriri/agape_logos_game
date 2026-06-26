import {AnagramIndex} from "./anagram_index";

export function letterKey(letters: string[]): string {
  return [...letters].sort().join("");
}

/**
 * Every word of length >= 2 spellable from the rack's letter multiset.
 * Enumerates subsets of letter positions (rack size <= 6 -> <= 64 subsets),
 * which respects duplicate letters naturally, and looks up each subset's
 * sorted key in the anagram index. Sorted by length then alphabetically.
 */
export function findAnswers(letters: string[], index: AnagramIndex): string[] {
  const n = letters.length;
  const keys = new Set<string>();
  for (let mask = 1; mask < 1 << n; mask++) {
    const subset: string[] = [];
    for (let i = 0; i < n; i++) {
      if (mask & (1 << i)) subset.push(letters[i]);
    }
    if (subset.length < 2) continue;
    keys.add(subset.sort().join(""));
  }
  const found = new Set<string>();
  for (const key of keys) {
    const words = index.get(key);
    if (words) {
      for (const w of words) found.add(w);
    }
  }
  return [...found].sort((a, b) => a.length - b.length || a.localeCompare(b));
}
