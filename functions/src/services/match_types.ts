import type {MatchSettings} from "../schemas/matches";

export type MatchStatus = "lobby" | "countdown" | "active" | "finished" | "cancelled";

export interface MatchPlayerDoc {
  uid: string;
  displayName: string;
  avatarId: string;
  isGuest: boolean;
  ready: boolean;
  connected: boolean;
  lastSeen: number;
  score: number;
  wordsFound: number;
  // Millis of the player's most recent accepted word (speed tiebreak) and of
  // finding the LAST answer (early finish). Absent until the first/last accept.
  lastWordAt?: number;
  finishedAt?: number;
  // Extra time (millis) this player has earned via time_boost, added on top of
  // the match's shared endsAt to compute their PERSONAL deadline.
  endsAtBonusMs?: number;
}

// One live powerup effect. Listed under the uid it acts ON: an offensive
// effect (fog_bank, letter_freeze) is filed under the TARGET's uid; a
// defensive/self effect (shield, double_points, combo_lock) is filed under
// the CASTER's uid. expiresAt === 0 means "armed until consumed" (shield).
export interface ActiveEffect {
  kind: string;
  byUid: string;
  startedAt: number;
  expiresAt: number; // 0 = until consumed
  payload: Record<string, unknown>;
}

// The stored matches/{matchId} document (plan 10 section 8.2) plus a server-only
// usedPuzzleIds helper (the letterKeys already drawn; both players now share
// puzzleId). usedPuzzleIds is not secret: a letterKey is just the sorted
// rack letters; the answers stay encrypted in the private rack.
export interface MatchData {
  matchId: string;
  code: string;
  status: MatchStatus;
  participants: string[];
  playerOrder: string[];
  createdBy: string;
  createdAt: number;
  startedAt: number;
  endsAt: number;
  settings: MatchSettings;
  players: Record<string, MatchPlayerDoc>;
  usedPuzzleIds?: string[];
  // The SHARED puzzle both players race on (same rack = fair max words/score).
  puzzleId?: string;
  // Live powerup effects, keyed by the uid each effect acts ON.
  activeEffects?: Record<string, ActiveEffect[]>;
  winner: string | null;
  // Present only on challenge matches: who challenged whom, and when. The
  // invitee joins as a participant only on ACCEPT (see challenge_service).
  challenge?: {byUid: string; toUid: string; at: number};
}
