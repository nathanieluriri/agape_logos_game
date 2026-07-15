import {db} from "../firebase";
import {computeWinner, maxBonus} from "./match_scoring";
import {releaseCode} from "./match_codes";
import {HttpError} from "../middleware/http_error";
import type {MatchData} from "./match_types";

// A stale lobby/countdown that never started is cancelled after this age.
export const kLobbyTtlMs = 15 * 60 * 1000;
// An unaccepted challenge (which may be a 6-hour async round) lives far longer
// than an ordinary abandoned lobby before the sweeper cancels it.
export const kChallengeTtlMs = 7 * 24 * 60 * 60 * 1000;

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

  // Early finish: once every participant has found ALL their answers, there is
  // nothing left to play; finalize immediately instead of waiting out endsAt.
  const allDone = m.status === "active" && m.participants.length >= 2 &&
    m.participants.every((p) => (m.players[p]?.finishedAt ?? 0) > 0);
  if (allDone) {
    await finalizeMatch(matchId);
    const done = await matchRef.get();
    return (done.data() as MatchData) ?? null;
  }
  // A time_boost pushes an individual player's deadline past the shared
  // endsAt; the match stays alive until the LATEST personal deadline passes.
  const boostedEndsAt = m.endsAt > 0 ? m.endsAt + maxBonus(m) : m.endsAt;
  if (boostedEndsAt > 0 && now >= boostedEndsAt && (m.status === "active" || m.status === "countdown")) {
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
    const m = d.data() as MatchData;
    // The query only filters on the shared endsAt; a time_boost can push an
    // individual player's personal deadline later, so re-check before ending.
    if (now < m.endsAt + maxBonus(m)) continue;
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
      // Async challenges (a 6-hour round) must outlive the 15-min lobby sweep;
      // they are cancelled only by the challenge-TTL pass below.
      if (m.settings.mode === "async") continue;
      await d.ref.update({status: "cancelled"});
      await releaseCode(m.code);
      // A never-accepted challenge leaves an invite doc in the invitee's
      // /challenges list; without this it lingers as UI cruft pointing at a
      // now-cancelled match forever.
      if (m.challenge) {
        await db.collection("users").doc(m.challenge.toUid).collection("challenges").doc(d.id).delete();
      }
      cancelled++;
    }
  }

  // Separate, much longer TTL for unaccepted challenges (the invitee never
  // joined). Reuses the same (status, createdAt) index.
  const challengeCutoff = now - kChallengeTtlMs;
  for (const status of ["lobby", "countdown"] as const) {
    const stale = await db
      .collection("matches")
      .where("status", "==", status)
      .where("createdAt", "<=", challengeCutoff)
      .limit(limit)
      .get();
    for (const d of stale.docs) {
      const m = d.data() as MatchData;
      if (!m.challenge) continue; // only unaccepted challenges use this TTL
      await d.ref.update({status: "cancelled"});
      await releaseCode(m.code);
      await db.collection("users").doc(m.challenge.toUid).collection("challenges").doc(d.id).delete();
      cancelled++;
    }
  }
  return {finalized, cancelled};
}

// Re-exported so a route can 404 cleanly if needed without importing HttpError
// twice; kept here to keep finalize the single owner of match settling.
export {HttpError};
