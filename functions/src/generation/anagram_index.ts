export function sortLetters(word: string): string {
  return word.split("").sort().join("");
}

export type AnagramIndex = Map<string, string[]>;

export function buildAnagramIndex(words: string[]): AnagramIndex {
  const index: AnagramIndex = new Map();
  for (const word of words) {
    const key = sortLetters(word);
    const bucket = index.get(key);
    if (bucket) {
      bucket.push(word);
    } else {
      index.set(key, [word]);
    }
  }
  return index;
}
