import type {Tier} from "../generation/config";
import type {MatchDifficulty, PowerupKind} from "../schemas/matches";

// Points per found word. Length-weighted so longer words are worth more, but the
// WINNER is decided by wordsFound (plan 10 section 3), not by score.
export function wordScore(word: string): number {
  return word.length;
}

export interface PlayerScoreLike {
  wordsFound: number;
  score: number;
  lastWordAt?: number;
}

// Winner by most words found; equal wordsFound tiebreaks by speed (earlier
// lastWordAt, i.e. faster to the tied count), then score, then draw.
// participants is the [uidA, uidB] array; returns a uid or "draw".
export function computeWinner(
  participants: string[],
  players: Record<string, PlayerScoreLike>,
): string {
  if (participants.length < 2) return participants[0] ?? "draw";
  const [a, b] = participants;
  const pa = players[a]; const pb = players[b];
  const wa = pa?.wordsFound ?? 0; const wb = pb?.wordsFound ?? 0;
  if (wa !== wb) return wa > wb ? a : b;
  const ta = pa?.lastWordAt ?? 0; const tb = pb?.lastWordAt ?? 0;
  if (ta > 0 && tb > 0 && ta !== tb) return ta < tb ? a : b; // faster to the tied count wins
  const sa = pa?.score ?? 0; const sb = pb?.score ?? 0;
  if (sa !== sb) return sa > sb ? a : b;
  return "draw";
}

// Contract powerup kind (plan 10 section 8.5) -> store base-item id it spends
// from users/{uid}.inventory (ids from functions/src/store/catalog.ts).
export const POWERUP_ITEM_ID: Record<PowerupKind, string> = {
  letter_freeze: "freeze_letter",
  fog_bank: "fog",
  scramble: "scramble",
  word_steal: "word_steal",
  shield: "shield",
  time_boost: "time_boost",
  double_points: "double_points",
  combo_lock: "combo_lock",
};

// Effect lifetime in millis per kind (0 = instant, or "until consumed" for
// shield). The server stamps expiresAt = now + this so both clients agree on
// when a timed effect ends.
export const POWERUP_DURATION_MS: Record<PowerupKind, number> = {
  letter_freeze: 10000,
  fog_bank: 8000,
  scramble: 0,
  word_steal: 0,
  shield: 0,
  time_boost: 0,
  double_points: 20000,
  combo_lock: 20000,
};

// The 4 kinds that act on the OPPONENT; everything else acts on the caster.
export const OFFENSIVE_KINDS: ReadonlySet<PowerupKind> =
  new Set(["letter_freeze", "fog_bank", "scramble", "word_steal"]);

// Millis a fired time_boost adds to the caster's personal deadline.
export const TIME_BOOST_MS = 30000;

// The max endsAtBonusMs across participants: how much later than the shared
// endsAt the match can still be alive (someone's personal deadline).
export function maxBonus(m: {participants: string[]; players: Record<string, {endsAtBonusMs?: number}>}): number {
  return Math.max(0, ...m.participants.map((p) => m.players[p]?.endsAtBonusMs ?? 0));
}

// Match difficulty -> pool tier for the rack draw (plan 10 section 8.2). The
// pool's "expert" tier is reserved.
export const DIFFICULTY_TIER: Record<MatchDifficulty, Tier> = {
  easy: "easy",
  medium: "medium",
  hard: "hard",
};
