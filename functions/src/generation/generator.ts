import {Tier, TIERS} from "./config";
import {WordData} from "./word_data";
import {AnagramIndex} from "./anagram_index";
import {findAnswers, letterKey} from "./rack";
import {meetsAnswerGate} from "./quality";
import {Rng, shuffle} from "./random";

/** True when every letter in the word is unique (no doubles, no triples). */
export function hasDistinctLetters(word: string): boolean {
  return new Set(word.split("")).size === word.length;
}

export interface RawPuzzle {
  tier: Tier;
  rackSize: number;
  letters: string[];
  letterKey: string;
  anchor: string;
  answers: string[];
  answerCount: number;
}

export function commonWordsOfLength(words: string[], length: number): string[] {
  return words.filter((w) => w.length === length);
}

export interface GenerateOptions {
  tier: Tier;
  count: number;
  wordData: WordData;
  index: AnagramIndex;
  existingKeys: Set<string>;
  rng: Rng;
}

export interface GenerateResult {
  puzzles: RawPuzzle[];
  shortfall: number;
}

/**
 * Anchor-word generation for one tier. Walks a shuffled list of common words of
 * the tier's rack size; each becomes a candidate rack. Skips racks whose
 * letterKey is already used (dedupe) or that fail the answer-count gate. Stops
 * at `count` puzzles or when candidates are exhausted (reported as shortfall).
 * Mutates `existingKeys` so the caller can share one set across tiers.
 */
export function generateTierBatch(opts: GenerateOptions): GenerateResult {
  const cfg = TIERS[opts.tier];
  // Only anchors within this tier's frequency horizon (the difficulty knob).
  const candidates = shuffle(
    commonWordsOfLength(opts.wordData.commonWords, cfg.rackSize).filter(
      (w) => opts.wordData.rank(w) < cfg.anchorCutoff && hasDistinctLetters(w),
    ),
    opts.rng,
  );

  const puzzles: RawPuzzle[] = [];
  for (const anchor of candidates) {
    if (puzzles.length >= opts.count) break;
    const letters = anchor.split("");
    const key = letterKey(letters);
    if (opts.existingKeys.has(key)) continue;

    // Two horizons: full-length words (the headline words, incl. the anchor)
    // count down to anchorCutoff; shorter sub-words only if common enough
    // (answerCutoff). Keeps the anchor always present while capping clutter.
    const answers = findAnswers(letters, opts.index).filter((w) => {
      const cutoff = w.length === cfg.rackSize ? cfg.anchorCutoff : cfg.answerCutoff;
      return opts.wordData.rank(w) < cutoff;
    });
    if (!meetsAnswerGate(answers.length, cfg)) continue;

    opts.existingKeys.add(key);
    puzzles.push({
      tier: opts.tier,
      rackSize: cfg.rackSize,
      letters,
      letterKey: key,
      anchor,
      answers,
      answerCount: answers.length,
    });
  }

  return {puzzles, shortfall: opts.count - puzzles.length};
}
