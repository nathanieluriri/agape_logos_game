import {FieldValue, Timestamp} from "firebase-admin/firestore";
import {db} from "../firebase";
import {
  COIN_CLAIM_AMOUNT,
  COIN_CLAIM_INTERVAL_MS,
  POWERUP_CLAIM_INTERVAL_MS,
  POWERUP_POOL,
  REWARD_MIN_LEVEL,
  Rng,
  shuffle,
} from "../rewards/config";

// Reward bookkeeping lives on the user doc (alongside coins + inventory) so a
// claim is a single-document atomic transaction.
interface RewardData {
  coinClaimAt?: Timestamp;
  powerupClaimAt?: Timestamp;
  // Remaining ids in the current weekly cycle (random order, drawn from the
  // front). Empty -> reshuffle the whole pool on the next claim.
  powerupBag?: string[];
  // Last granted id, to avoid an adjacent repeat across a cycle boundary.
  lastPowerupId?: string | null;
}

// Milliseconds until [last] + [intervalMs]; 0 when already elapsed / never set.
function cooldownRemaining(
  last: Timestamp | undefined | null,
  intervalMs: number,
  now: number,
): number {
  if (!last) return 0;
  const elapsed = now - last.toMillis();
  return elapsed >= intervalMs ? 0 : intervalMs - elapsed;
}

export interface RewardStatus {
  unlocked: boolean;
  minLevel: number;
  level: number;
  coins: {amount: number; claimable: boolean; nextClaimInMs: number};
  powerup: {claimable: boolean; nextClaimInMs: number};
}

// Read-only: computes eligibility from stored timestamps. No writes, so the
// client can poll it freely (e.g. on the home screen) without cost concerns.
export async function getRewardStatus(uid: string): Promise<RewardStatus> {
  const snap = await db.collection("users").doc(uid).get();
  const data = (snap.data() ?? {}) as Record<string, unknown>;
  const level = (data.highestLevel as number) ?? 0;
  const rewards = (data.rewards as RewardData) ?? {};
  const now = Date.now();
  const unlocked = level >= REWARD_MIN_LEVEL;

  const coinRemaining = cooldownRemaining(rewards.coinClaimAt, COIN_CLAIM_INTERVAL_MS, now);
  const powerupRemaining = cooldownRemaining(rewards.powerupClaimAt, POWERUP_CLAIM_INTERVAL_MS, now);
  return {
    unlocked,
    minLevel: REWARD_MIN_LEVEL,
    level,
    coins: {
      amount: COIN_CLAIM_AMOUNT,
      claimable: unlocked && coinRemaining === 0,
      nextClaimInMs: coinRemaining,
    },
    powerup: {
      claimable: unlocked && powerupRemaining === 0,
      nextClaimInMs: powerupRemaining,
    },
  };
}

export type ClaimResult<T> =
  | ({ok: true} & T)
  | {ok: false; reason: "locked"; minLevel: number}
  | {ok: false; reason: "cooldown"; nextClaimInMs: number};

// Claims the 72h coin reward. The cooldown itself is the dedup: an immediate
// replay finds the interval not elapsed and is rejected, so no double-grant.
export async function claimCoins(
  uid: string,
): Promise<ClaimResult<{claimed: number; coins: number; nextClaimInMs: number}>> {
  const ref = db.collection("users").doc(uid);
  return db.runTransaction<
    ClaimResult<{claimed: number; coins: number; nextClaimInMs: number}>
  >(async (tx) => {
    const snap = await tx.get(ref);
    const data = (snap.data() ?? {}) as Record<string, unknown>;
    const level = (data.highestLevel as number) ?? 0;
    if (level < REWARD_MIN_LEVEL) {
      return {ok: false, reason: "locked", minLevel: REWARD_MIN_LEVEL};
    }
    const rewards = (data.rewards as RewardData) ?? {};
    const rem = cooldownRemaining(rewards.coinClaimAt, COIN_CLAIM_INTERVAL_MS, Date.now());
    if (rem > 0) return {ok: false, reason: "cooldown", nextClaimInMs: rem};

    tx.set(
      ref,
      {
        coins: FieldValue.increment(COIN_CLAIM_AMOUNT),
        rewards: {coinClaimAt: FieldValue.serverTimestamp()},
        updatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true},
    );
    return {
      ok: true,
      claimed: COIN_CLAIM_AMOUNT,
      coins: ((data.coins as number) ?? 0) + COIN_CLAIM_AMOUNT,
      nextClaimInMs: COIN_CLAIM_INTERVAL_MS,
    };
  });
}

// Claims the weekly powerup via a shuffle bag: draw from the front of the
// current cycle's random order; when the bag empties, reshuffle the whole pool
// (swapping so the first draw of the new cycle is never the same as the last of
// the old one). Guarantees no repeat until every powerup has been granted, and
// that each is eventually guaranteed within a cycle.
export async function claimPowerup(
  uid: string,
  rng: Rng = Math.random,
): Promise<
  ClaimResult<{granted: string; inventory: Record<string, number>; nextClaimInMs: number}>
> {
  const ref = db.collection("users").doc(uid);
  return db.runTransaction<
    ClaimResult<{granted: string; inventory: Record<string, number>; nextClaimInMs: number}>
  >(async (tx) => {
    const snap = await tx.get(ref);
    const data = (snap.data() ?? {}) as Record<string, unknown>;
    const level = (data.highestLevel as number) ?? 0;
    if (level < REWARD_MIN_LEVEL) {
      return {ok: false, reason: "locked", minLevel: REWARD_MIN_LEVEL};
    }
    const rewards = (data.rewards as RewardData) ?? {};
    const rem = cooldownRemaining(rewards.powerupClaimAt, POWERUP_CLAIM_INTERVAL_MS, Date.now());
    if (rem > 0) return {ok: false, reason: "cooldown", nextClaimInMs: rem};

    // Drop any stale ids (pool changed since the bag was written).
    let bag = [...(rewards.powerupBag ?? [])].filter((id) => POWERUP_POOL.includes(id));
    const lastId = rewards.lastPowerupId ?? null;
    if (bag.length === 0) {
      bag = shuffle(POWERUP_POOL, rng);
      if (bag.length > 1 && bag[0] === lastId) {
        [bag[0], bag[1]] = [bag[1], bag[0]];
      }
    }
    const granted = bag[0];
    const rest = bag.slice(1);
    const inventory = (data.inventory as Record<string, number>) ?? {};

    tx.set(
      ref,
      {
        inventory: {[granted]: FieldValue.increment(1)},
        rewards: {
          powerupClaimAt: FieldValue.serverTimestamp(),
          powerupBag: rest,
          lastPowerupId: granted,
        },
        updatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true},
    );
    return {
      ok: true,
      granted,
      inventory: {...inventory, [granted]: (inventory[granted] ?? 0) + 1},
      nextClaimInMs: POWERUP_CLAIM_INTERVAL_MS,
    };
  });
}
