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
}

// The stored matches/{matchId} document (plan 10 section 8.2) plus a server-only
// usedPuzzleIds helper (the letterKeys already drawn, so the two players get
// DIFFERENT words). usedPuzzleIds is not secret: a letterKey is just the sorted
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
  winner: string | null;
}
