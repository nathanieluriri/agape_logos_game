import * as path from "path";

export type Tier = "easy" | "medium" | "hard" | "expert";

export interface TierConfig {
  tier: Tier;
  rackSize: number;
  minAnswers: number;
  poolTarget: number;
}

export const TIERS: Record<Tier, TierConfig> = {
  easy: {tier: "easy", rackSize: 3, minAnswers: 3, poolTarget: 200},
  medium: {tier: "medium", rackSize: 4, minAnswers: 5, poolTarget: 350},
  hard: {tier: "hard", rackSize: 5, minAnswers: 7, poolTarget: 350},
  expert: {tier: "expert", rackSize: 6, minAnswers: 9, poolTarget: 100},
};

export const TIER_ORDER: Tier[] = ["easy", "medium", "hard", "expert"];

// A word counts as "common" if it appears within the first N entries of the
// frequency-ranked list (most frequent first). Tunable while eyeballing output.
export const COMMON_FREQUENCY_CUTOFF = 50000;

export const DEFINITION_CONCURRENCY = 5;
export const DEFINITION_MAX_RETRIES = 3;

// Bump when the algorithm changes so regenerated puzzles are distinguishable.
export const GEN_VERSION = 1;

const DATA_DIR = path.resolve(__dirname, "../../data");
export const VALIDITY_FILE = path.join(DATA_DIR, "enable.txt");
export const FREQUENCY_FILE = path.join(DATA_DIR, "word_frequency.txt");
export const DEFINITIONS_CACHE_FILE = path.join(DATA_DIR, "definitions_cache.json");
