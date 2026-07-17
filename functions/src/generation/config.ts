import * as path from "path";

export type Tier = "easy" | "medium" | "hard" | "expert";

export interface TierConfig {
  tier: Tier;
  rackSize: number;
  minAnswers: number;
  // Hard cap on answers per puzzle. A rack yielding more is rejected.
  maxAnswers: number;
  // How rare the anchor (and any full-rack anagram) may be. The difficulty knob:
  // wider = rarer base words allowed.
  anchorCutoff: number;
  // How common a shorter sub-word must be to count as an answer. Kept modest so
  // boards stay small (<= maxAnswers) and findable.
  answerCutoff: number;
  poolTarget: number;
}

// Difficulty comes from rack size + anchor rarity (anchorCutoff); answerCutoff
// keeps the board small and findable. Starting points; tune via the shortfall
// report and regenerate.
export const TIERS: Record<Tier, TierConfig> = {
  easy: {tier: "easy", rackSize: 3, minAnswers: 3, maxAnswers: 5, anchorCutoff: 15000, answerCutoff: 15000, poolTarget: 200},
  medium: {tier: "medium", rackSize: 4, minAnswers: 3, maxAnswers: 5, anchorCutoff: 30000, answerCutoff: 18000, poolTarget: 350},
  // Rack 5-6 racks almost always spell more than 5 common words, so a strict
  // max of 5 leaves these tiers nearly unfillable. Easy/medium keep the calm
  // 5-answer cap; hard/expert relax it so the pool can fill.
  hard: {tier: "hard", rackSize: 5, minAnswers: 3, maxAnswers: 7, anchorCutoff: 50000, answerCutoff: 20000, poolTarget: 350},
  expert: {tier: "expert", rackSize: 6, minAnswers: 3, maxAnswers: 8, anchorCutoff: 90000, answerCutoff: 22000, poolTarget: 100},
};

export const TIER_ORDER: Tier[] = ["easy", "medium", "hard", "expert"];

// The widest horizon any tier draws from, so the shared word set / anagram index
// loads deep enough for both anchors and answers.
export const MAX_FREQUENCY_CUTOFF = Math.max(
  ...TIER_ORDER.flatMap((t) => [TIERS[t].anchorCutoff, TIERS[t].answerCutoff]),
);

export const DEFINITION_CONCURRENCY = 5;
export const DEFINITION_MAX_RETRIES = 3;

// Bump when the algorithm changes so regenerated puzzles are distinguishable.
// v3: split anchor/answer cutoffs, max 5 answers, distinct-letter racks, and
// reject any rack with an undefined answer.
export const GEN_VERSION = 3;

const DATA_DIR = path.resolve(__dirname, "../../data");
export const VALIDITY_FILE = path.join(DATA_DIR, "enable.txt");
export const FREQUENCY_FILE = path.join(DATA_DIR, "word_frequency.txt");
export const DEFINITIONS_CACHE_FILE = path.join(DATA_DIR, "definitions_cache.json");
// Newline-delimited list of words to exclude everywhere (anchors and answers).
// Missing file is treated as empty, so the filter is opt-in.
export const BLOCKLIST_FILE = path.join(DATA_DIR, "blocklist.txt");
// Bundled offline dictionary: word -> definition (WordNet glosses, built by
// scripts/build_dictionary.ts) plus a small hand-authored supplement for common
// function/irregular words WordNet omits. Generation reads these; no network.
export const WORDNET_DEFS_FILE = path.join(DATA_DIR, "wordnet_defs.json");
export const DICT_SUPPLEMENT_FILE = path.join(DATA_DIR, "dict_supplement.json");
