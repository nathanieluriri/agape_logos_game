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
  winner: string | null;
  // Present only on challenge matches: who challenged whom, and when. The
  // invitee joins as a participant only on ACCEPT (see challenge_service).
  challenge?: {byUid: string; toUid: string; at: number};
}
