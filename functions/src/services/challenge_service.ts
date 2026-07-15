import {FieldValue} from "firebase-admin/firestore";
import {db} from "../firebase";
import {areFriends} from "./social_service";
import {getOrCreateProfile} from "./profile_service";
import {releaseCode} from "./match_codes";
import {sendToUser} from "./messaging_service";
import {addParticipant, applyStart, createMatch, kAsyncRoundMs} from "./match_service";
import {settleMatch} from "./match_finalize";
import type {MatchData} from "./match_types";
import type {MatchSettings} from "../schemas/matches";

// The three statuses that count as an in-flight match between two players.
const OPEN_STATUSES = ["lobby", "countdown", "active"] as const;

export interface ActiveMatchView {
  matchId: string;
  mode: string;
  status: string;
  opponentUid: string | null;
  opponentName: string | null;
  myScore: number;
  opponentScore: number;
  startedAt: number;
  endsAt: number;
}

// PURE - the one-open-challenge-per-friend-pair guard. Given the caller's open
// matches (each already reduced to participants + status), is there one that
// pairs [a] and [b]? Unit-tested with no emulator.
export function hasOpenMatchWith(
  openMatches: {participants: string[]; status: string}[],
  a: string,
  b: string,
): boolean {
  const OPEN = new Set(OPEN_STATUSES as readonly string[]);
  return openMatches.some((m) =>
    OPEN.has(m.status) && m.participants.includes(a) && m.participants.includes(b));
}

// A pending challenge's invitee is stored on `challenge.toUid`, NOT yet in
// `participants` (they join only on accept). Fold that pending target into the
// effective participant list so hasOpenMatchWith blocks a duplicate challenge.
function effectiveParticipants(m: MatchData): string[] {
  const pending = m.challenge?.toUid ? [m.challenge.toUid] : [];
  return [...m.participants, ...pending];
}

async function openMatchesFor(uid: string): Promise<MatchData[]> {
  const snap = await db
    .collection("matches")
    .where("participants", "array-contains", uid)
    .where("status", "in", [...OPEN_STATUSES])
    .get();
  return snap.docs.map((d) => d.data() as MatchData);
}

// Best-effort outcome push to the challenger; a push failure never fails the
// response (mirrors the friend-request trigger).
async function notify(uid: string, title: string, body: string, data: Record<string, string>): Promise<void> {
  try {
    await sendToUser(uid, {title, body, data});
  } catch (e) {
    console.error(`challenge push failed for ${uid}`, e);
  }
}

// POST /matches/challenge. Verifies friendship, enforces one open challenge per
// pair, then creates the challenger's side (rack drawn by createMatch) and writes
// the invite doc the invitee (and the push trigger) reads.
export async function challengeFriend(
  fromUid: string,
  fromIsGuest: boolean,
  toUid: string,
  idempotencyKey: string,
  settings: MatchSettings,
): Promise<{ok: true; matchId: string} | {ok: false; reason: "not_friends" | "already_challenged"}> {
  if (!(await areFriends(fromUid, toUid))) return {ok: false, reason: "not_friends"};

  const rows = (await openMatchesFor(fromUid)).map((m) => ({
    participants: effectiveParticipants(m),
    status: m.status,
  }));
  if (hasOpenMatchWith(rows, fromUid, toUid)) return {ok: false, reason: "already_challenged"};

  const {matchId} = await createMatch(fromUid, fromIsGuest, idempotencyKey, settings);
  const me = await getOrCreateProfile(fromUid);
  const at = Date.now();
  await db.collection("matches").doc(matchId).update({
    challenge: {byUid: fromUid, toUid, at},
  });
  await db.collection("users").doc(toUid).collection("challenges").doc(matchId).set({
    matchId,
    byUid: fromUid,
    handle: me.handle,
    displayName: me.displayName,
    avatarId: me.avatarId,
    mode: settings.mode,
    at: FieldValue.serverTimestamp(),
  });
  return {ok: true, matchId};
}

// POST /matches/:id/respond. Accept: add the invitee as a participant (draws
// their DIFFERENT puzzle) and start by mode (async = 6h clock from now, live =
// countdown). Decline: cancel + free the code. Notifies the challenger either way.
export async function respondChallenge(
  uid: string,
  isGuest: boolean,
  matchId: string,
  accept: boolean,
): Promise<{ok: true; status: string} | {ok: false; reason: "no_challenge"}> {
  const matchRef = db.collection("matches").doc(matchId);
  const inviteRef = db.collection("users").doc(uid).collection("challenges").doc(matchId);

  // ONE-SHOT GUARD (atomic): a challenge is answerable only while the match is
  // still "lobby" and only by its invitee. Clearing `challenge` and the invite
  // doc HERE, inside the same transaction as the guard read, is what makes
  // respond one-shot: a replay (or a concurrent second call) sees no challenge
  // and cleanly returns no_challenge instead of re-driving the state machine
  // (resetting an async deadline, cancelling a live game, or resurrecting a
  // finished match). addParticipant + the rack draw + the mode-specific start
  // below are NOT transaction-safe (pool queries), so they run after this guard
  // has already made the challenge unanswerable a second time.
  const m = await db.runTransaction(async (tx) => {
    const snap = await tx.get(matchRef);
    if (!snap.exists) return null;
    const data = snap.data() as MatchData;
    if (data.status !== "lobby" || data.challenge?.toUid !== uid) return null;
    tx.update(matchRef, {challenge: FieldValue.delete()});
    tx.delete(inviteRef);
    return data;
  });
  if (!m) return {ok: false, reason: "no_challenge"};

  const challengerUid = m.challenge!.byUid;
  const responder = await getOrCreateProfile(uid);

  if (!accept) {
    await matchRef.update({status: "cancelled"});
    await releaseCode(m.code);
    await notify(challengerUid, "Challenge declined", `${responder.displayName} declined your challenge`, {
      type: "challenge_declined", matchId, byUid: uid,
    });
    return {ok: true, status: "cancelled"};
  }

  // Draw the responder's rack (a DIFFERENT puzzle) through the shared join core.
  await addParticipant(uid, isGuest, matchId);

  let status: string;
  if (m.settings.mode === "async") {
    const now = Date.now();
    await matchRef.update({status: "active", startedAt: now, endsAt: now + kAsyncRoundMs});
    status = "active";
  } else {
    status = await matchRef.firestore.runTransaction(async (tx) => {
      const s = await tx.get(matchRef);
      applyStart(tx, matchRef, s.data() as MatchData);
      return "countdown";
    });
  }

  await notify(challengerUid, "Challenge accepted", `${responder.displayName} accepted your challenge`, {
    type: "challenge_accepted", matchId, byUid: uid,
  });
  return {ok: true, status};
}

// GET /me/matches/active. The caller's in-flight matches, mapped to a compact
// view for the resume-games screen. Reuses the participants+status index.
export async function listActiveMatches(uid: string): Promise<ActiveMatchView[]> {
  const candidates = await openMatchesFor(uid);
  // Settle each candidate first (the list is small, bounded by the one-open-
  // challenge-per-pair guard): a stale 6h async match finalizes right here
  // instead of lingering as "active" forever, and anything that settles to
  // finished/cancelled is dropped from the resume list.
  const OPEN = new Set(OPEN_STATUSES as readonly string[]);
  const matches: MatchData[] = [];
  for (const c of candidates) {
    const s = await settleMatch(c.matchId);
    if (s && OPEN.has(s.status)) matches.push(s);
  }
  return matches.map((m) => {
    const opponentUid = m.participants.find((p) => p !== uid) ?? null;
    const opp = opponentUid ? m.players[opponentUid] : undefined;
    const me = m.players[uid];
    return {
      matchId: m.matchId,
      mode: m.settings.mode ?? "live",
      status: m.status,
      opponentUid,
      opponentName: opp?.displayName ?? null,
      myScore: me?.score ?? 0,
      opponentScore: opp?.score ?? 0,
      startedAt: m.startedAt,
      endsAt: m.endsAt,
    };
  });
}
