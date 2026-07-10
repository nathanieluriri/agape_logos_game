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
}

// Winner by most words found; equal wordsFound is a draw. participants is the
// [uidA, uidB] array; returns a uid or "draw".
export function computeWinner(
  participants: string[],
  players: Record<string, PlayerScoreLike>,
): string {
  if (participants.length < 2) return participants[0] ?? "draw";
  const [a, b] = participants;
  const wa = players[a]?.wordsFound ?? 0;
  const wb = players[b]?.wordsFound ?? 0;
  if (wa > wb) return a;
  if (wb > wa) return b;
  return "draw";
}

// Contract powerup kind (plan 10 section 8.5) -> store base-item id it spends
// from users/{uid}.inventory (ids from functions/src/store/catalog.ts).
export const POWERUP_ITEM_ID: Record<PowerupKind, string> = {
  letter_freeze: "freeze_letter",
  fog_bank: "fog",
  scramble: "scramble",
  word_steal: "word_steal",
};

// Effect lifetime in millis per kind (0 = instant). The server stamps
// expiresAt = now + this so both clients agree on when a freeze/fog ends.
export const POWERUP_DURATION_MS: Record<PowerupKind, number> = {
  letter_freeze: 10000,
  fog_bank: 8000,
  scramble: 0,
  word_steal: 0,
};

// Match difficulty -> pool tier for the rack draw (plan 10 section 8.2). The
// pool's "expert" tier is reserved.
export const DIFFICULTY_TIER: Record<MatchDifficulty, Tier> = {
  easy: "easy",
  medium: "medium",
  hard: "hard",
};
