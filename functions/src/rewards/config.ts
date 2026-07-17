import {STORE_ITEMS} from "../store/catalog";

// Rewards tuning. All eligibility is computed lazily from timestamps on each
// request (no cron / background jobs): a claim writes "now", and the next claim
// simply checks whether the interval has elapsed. Nothing accrues or stockpiles
// while unclaimed - the reward is a single claimable, not a running total.

export const REWARD_MIN_LEVEL = 5; // must reach this before rewards unlock

export const COIN_CLAIM_INTERVAL_MS = 72 * 60 * 60 * 1000; // every 72 hours
export const COIN_CLAIM_AMOUNT = 400; // flat, does not stockpile

export const POWERUP_CLAIM_INTERVAL_MS = 7 * 24 * 60 * 60 * 1000; // weekly

// The weekly powerup pool: base powerups only (no hints, no bundles). Derived
// from the store catalog so it stays in sync as items are added/removed.
export const POWERUP_POOL: string[] = STORE_ITEMS
  .filter((i) => i.category === "powerup" && !i.grants)
  .map((i) => i.id);

export type Rng = () => number;

// Fisher-Yates. Returns a new shuffled copy; the seam-friendly [rng] makes the
// weekly draw deterministic in tests.
export function shuffle<T>(arr: readonly T[], rng: Rng = Math.random): T[] {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}
