import * as path from "path";

export type Tier = "easy" | "medium" | "hard" | "expert";

export interface TierConfig {
  tier: Tier;
  rackSize: number;
  minAnswers: number;
  // Optional upper bound on answers; a rack yielding more than this is rejected
  // as too crowded. Unset by default (no cap). Set per tier to taste.
  maxAnswers?: number;
  // How deep into the frequency-ranked list this tier may draw from. Smaller =
  // only very common words (easier); larger = rarer words allowed (harder).
  // Both anchors and answers are filtered by it. The per-tier difficulty knob.
  frequencyCutoff: number;
  poolTarget: number;
}

// Per-tier difficulty is tuned here: rack size, the answer-count gate
// (minAnswers / optional maxAnswers), and how rare a word each tier may use
// (frequencyCutoff). Starting points; adjust freely and regenerate.
export const TIERS: Record<Tier, TierConfig> = {
  easy: {tier: "easy", rackSize: 3, minAnswers: 3, frequencyCutoff: 15000, poolTarget: 200},
  medium: {tier: "medium", rackSize: 4, minAnswers: 5, frequencyCutoff: 30000, poolTarget: 350},
  hard: {tier: "hard", rackSize: 5, minAnswers: 7, frequencyCutoff: 50000, poolTarget: 350},
  expert: {tier: "expert", rackSize: 6, minAnswers: 9, frequencyCutoff: 90000, poolTarget: 100},
};

export const TIER_ORDER: Tier[] = ["easy", "medium", "hard", "expert"];

// The widest tier horizon. The shared common-word set is loaded this deep so
// every tier can filter down from one index (see WordData.rank).
export const MAX_FREQUENCY_CUTOFF = Math.max(
  ...TIER_ORDER.map((t) => TIERS[t].frequencyCutoff),
);

export const DEFINITION_CONCURRENCY = 5;
export const DEFINITION_MAX_RETRIES = 3;

// Bump when the algorithm changes so regenerated puzzles are distinguishable.
// v2: every answer must have a definition, per-tier frequency cutoffs, and the
// profanity blocklist.
export const GEN_VERSION = 2;

const DATA_DIR = path.resolve(__dirname, "../../data");
export const VALIDITY_FILE = path.join(DATA_DIR, "enable.txt");
export const FREQUENCY_FILE = path.join(DATA_DIR, "word_frequency.txt");
export const DEFINITIONS_CACHE_FILE = path.join(DATA_DIR, "definitions_cache.json");
// Newline-delimited list of words to exclude everywhere (anchors and answers).
// Missing file is treated as empty, so the filter is opt-in.
export const BLOCKLIST_FILE = path.join(DATA_DIR, "blocklist.txt");
