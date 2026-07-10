import {db} from "../firebase";
import {computeWinner} from "./match_scoring";
import {releaseCode} from "./match_codes";
import {HttpError} from "../middleware/http_error";
import type {MatchData} from "./match_types";

// A stale lobby/countdown that never started is cancelled after this age.
export const kLobbyTtlMs = 15 * 60 * 1000;

export interface FinalizeOptions {
  // Force a winner (used by leave/forfeit). null/undefined -> compute by wordsFound.
  winnerOverride?: string | null;
}

// Finalizes a match exactly once: winner + status finished + a history doc for
// each player, then frees the code. Idempotent (returns early if already ended).
export async function finalizeMatch(
  matchId: string,
  opts: FinalizeOptions = {},
): Promise<void> {
  const matchRef = db.collection("matches").doc(matchId);
  let code: string | undefined;

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(matchRef);
    if (!snap.exists) return;
    const m = snap.data() as MatchData;
    code = m.code;
    if (m.status === "finished" || m.status === "cancelled") return;

    const now = Date.now();
    const winner =
      opts.winnerOverride !== undefined && opts.winnerOverride !== null
        ? opts.winnerOverride
        : computeWinner(m.participants, m.players);

    tx.update(matchRef, {status: "finished", winner, endsAt: m.endsAt || now});

    // History for BOTH players (plan 10 section 8.1). Doc id = matchId -> writing
    // twice is idempotent (same content).
    for (const pid of m.participants) {
      const otherId = m.participants.find((p) => p !== pid);
      const me = m.players[pid];
      const opp = otherId ? m.players[otherId] : undefined;
      const result = winner === "draw" ? "draw" : winner === pid ? "win" : "loss";
      tx.set(db.collection("users").doc(pid).collection("matchHistory").doc(matchId), {
        matchId,
        opponentUid: otherId ?? null,
        opponentName: opp?.displayName ?? "Unknown",
        result,
        score: me?.score ?? 0,
        opponentScore: opp?.score ?? 0,
        endedAt: now,
        settings: m.settings,
      });
    }
  });

  if (code) await releaseCode(code); // merge write; safe if already released
}

// Advances a match by the clock and PERSISTS the change, returning the effective
// match doc. Used by GET/submit/powerup so timers are server-authoritative:
//   countdown -> active   once startedAt has passed
//   active    -> finished (finalize) once endsAt has passed
// A no-op (single read) when nothing changed.
export async function settleMatch(matchId: string): Promise<MatchData | null> {
  const matchRef = db.collection("matches").doc(matchId);
  const snap = await matchRef.get();
  if (!snap.exists) return null;
  const m = snap.data() as MatchData;
  const now = Date.now();

  if (m.endsAt > 0 && now >= m.endsAt && (m.status === "active" || m.status === "countdown")) {
    await finalizeMatch(matchId);
    const done = await matchRef.get();
    return (done.data() as MatchData) ?? null;
  }
  if (m.status === "countdown" && m.startedAt > 0 && now >= m.startedAt) {
    await matchRef.update({status: "active"});
    return {...m, status: "active"};
  }
  return m;
}

// Sweeps abandoned matches (called by the scheduled matchSweep): finalizes active
// matches past endsAt that nobody touched, then cancels stale lobbies/countdowns
// and frees their codes. Bounded per run.
// PLAN: needs two composite indexes on matches: (status, endsAt) and
// (status, createdAt); added to firestore.indexes.json in plan 11 Task 8.
export async function sweepStaleMatches(
  limit = 200,
): Promise<{finalized: number; cancelled: number}> {
  const now = Date.now();
  let finalized = 0;
  let cancelled = 0;

  const expired = await db
    .collection("matches")
    .where("status", "==", "active")
    .where("endsAt", "<=", now)
    .limit(limit)
    .get();
  for (const d of expired.docs) {
    await finalizeMatch(d.id);
    finalized++;
  }

  const cutoff = now - kLobbyTtlMs;
  for (const status of ["lobby", "countdown"] as const) {
    const stale = await db
      .collection("matches")
      .where("status", "==", status)
      .where("createdAt", "<=", cutoff)
      .limit(limit)
      .get();
    for (const d of stale.docs) {
      const m = d.data() as MatchData;
      await d.ref.update({status: "cancelled"});
      await releaseCode(m.code);
      cancelled++;
    }
  }
  return {finalized, cancelled};
}

// Re-exported so a route can 404 cleanly if needed without importing HttpError
// twice; kept here to keep finalize the single owner of match settling.
export {HttpError};
