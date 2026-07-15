import {FieldValue} from "firebase-admin/firestore";
import {db} from "../firebase";
import {Rng} from "../generation/random";
import {Tier} from "../generation/config";
import {deriveAnswerKey} from "../crypto/answer_cipher";
import {encryptPuzzle, fetchPuzzles} from "./assignment_service";
import {DIFFICULTY_TIER} from "./match_scoring";
import {reserveCode, releaseCode, lookupCode} from "./match_codes";
import {getOrCreateProfile} from "./profile_service";
import {themedPuzzleId} from "./theme_service";
import {finalizeMatch} from "./match_finalize";
import {HttpError} from "../middleware/http_error";
import type {MatchData, MatchPlayerDoc} from "./match_types";
import type {MatchSettings} from "../schemas/matches";

export const kMaxPlayers = 2;
// A short shared countdown before play starts, so both clients agree on the go
// moment (startedAt) via one server transition.
export const kCountdownMs = 3000;
// An async challenge is a 6-hour round; its clock starts when the friend accepts.
export const kAsyncRoundMs = 6 * 60 * 60 * 1000;

const defaultRng: Rng = () => Math.random();

// --- rack draw -------------------------------------------------------------

// Random lower bound in [0,1) for the pool's `random` window (added in plan 02).
function randomStart(rng: Rng): number {
  return Math.min(0.999999, Math.max(0, rng()));
}

// Picks one puzzle id from [tier] not in [exclude], using the bounded
// random-window query (plan 02's `random` field + the tier+random index). Falls
// back to a plain scan if the pool predates the `random` backfill.
async function drawRandomPuzzleId(
  tier: Tier,
  exclude: Set<string>,
  rng: Rng,
): Promise<string | null> {
  const col = db.collection("puzzles").where("tier", "==", tier);
  const start = randomStart(rng);
  const forward = await col.where("random", ">=", start).orderBy("random").limit(12).select().get();
  for (const d of forward.docs) if (!exclude.has(d.id)) return d.id;
  const wrap = await col.where("random", "<", start).orderBy("random").limit(12).select().get();
  for (const d of wrap.docs) if (!exclude.has(d.id)) return d.id;
  // PLAN: fallback for a pool without `random` (pre plan-02 backfill).
  const any = await col.limit(50).select().get();
  for (const d of any.docs) if (!exclude.has(d.id)) return d.id;
  return null;
}

// Draws a puzzle, encrypts its answers with the player's per-user key, and writes
// the private rack doc (plan 10 section 8.3). Returns the drawn puzzle id.
async function drawRackForPlayer(
  matchId: string,
  uid: string,
  tier: Tier,
  exclude: Set<string>,
  rng: Rng,
  themeId: string | null = null,
  reusePuzzleId: string | null = null,
): Promise<string> {
  // A non-null reusePuzzleId skips the draw entirely: the joiner gets the SAME
  // puzzle as the creator so max words/score are identical (fair race).
  let id: string | null = reusePuzzleId;
  // Themed matches prefer a theme-tagged puzzle; the fallback is the untethered
  // draw, so this branch is inert until themes are seeded (plan 11 Task 9).
  if (!id && themeId) id = await themedPuzzleId(themeId, tier, exclude);
  if (!id) id = await drawRandomPuzzleId(tier, exclude, rng);
  if (!id) throw new HttpError(409, `no puzzle available for tier ${tier}`);
  const [puzzle] = await fetchPuzzles([id]);
  if (!puzzle) throw new HttpError(409, `puzzle ${id} not found`);
  const key = deriveAnswerKey(uid);
  const wire = encryptPuzzle(key, puzzle);
  await db.collection("matches").doc(matchId).collection("racks").doc(uid).set({
    uid,
    letters: wire.letters,
    letterKey: wire.letterKey,
    rackSize: wire.rackSize,
    answers: wire.answers,
    answerCount: wire.answerCount,
    foundWords: [],
  });
  return id;
}

// --- player doc ------------------------------------------------------------

async function buildPlayer(uid: string, isGuest: boolean): Promise<MatchPlayerDoc> {
  const profile = await getOrCreateProfile(uid);
  // Guests keep an anonymous uid; give them a friendly generated name if they
  // never set one (the default profile name is "Player").
  const displayName =
    isGuest && profile.displayName === "Player"
      ? `Guest ${uid.slice(0, 4).toUpperCase()}`
      : profile.displayName;
  return {
    uid,
    displayName,
    avatarId: profile.avatarId,
    isGuest,
    ready: false,
    connected: true,
    lastSeen: Date.now(),
    score: 0,
    wordsFound: 0,
  };
}

// --- create ----------------------------------------------------------------

// Creates a lobby: reserves a unique code, writes the match doc, draws the
// creator's rack. Idempotent on [idempotencyKey] via users/{uid}/matchCreates.
export async function createMatch(
  uid: string,
  isGuest: boolean,
  idempotencyKey: string,
  settings: MatchSettings,
  rng: Rng = defaultRng,
): Promise<{matchId: string; code: string}> {
  const createRef = db.collection("users").doc(uid).collection("matchCreates").doc(idempotencyKey);
  const existing = await createRef.get();
  if (existing.exists) {
    const d = existing.data() as {matchId: string; code: string};
    return {matchId: d.matchId, code: d.code};
  }

  const matchRef = db.collection("matches").doc();
  const matchId = matchRef.id;
  const code = await reserveCode(matchId, rng);
  const player = await buildPlayer(uid, isGuest);
  const now = Date.now();

  await matchRef.set({
    matchId,
    code,
    status: "lobby",
    participants: [uid],
    playerOrder: [uid],
    createdBy: uid,
    createdAt: now,
    startedAt: 0,
    endsAt: 0,
    settings,
    players: {[uid]: player},
    usedPuzzleIds: [],
    winner: null,
  } as MatchData);

  const tier = DIFFICULTY_TIER[settings.difficulty];
  const pid = await drawRackForPlayer(matchId, uid, tier, new Set(), rng, settings.theme);
  await matchRef.update({usedPuzzleIds: FieldValue.arrayUnion(pid), puzzleId: pid});
  await createRef.set({matchId, code, at: now});
  return {matchId, code};
}

// --- join ------------------------------------------------------------------

// Adds [uid] as a participant of an existing lobby by id and writes their rack
// (the SAME puzzle as the creator's, via puzzleId). Attach + cap check run
// in a transaction; the rack draw (pool queries) runs after. Idempotent:
// re-adding an existing participant is a no-op. Throws 409 if not joinable.
//
// This is the shared body of joinMatch; the challenge accept path reuses it by
// matchId so both entry points draw racks through the exact same tested logic.
export async function addParticipant(
  uid: string,
  isGuest: boolean,
  matchId: string,
  rng: Rng = defaultRng,
): Promise<void> {
  const matchRef = db.collection("matches").doc(matchId);
  const player = await buildPlayer(uid, isGuest);

  const {tier, alreadyIn, exclude, theme, puzzleId} = await db.runTransaction(async (tx) => {
    const snap = await tx.get(matchRef);
    if (!snap.exists) throw new HttpError(404, "match not found");
    const m = snap.data() as MatchData;
    const t = DIFFICULTY_TIER[m.settings.difficulty];
    const ex = new Set(m.usedPuzzleIds ?? []);
    const th = m.settings.theme;
    const pz = m.puzzleId ?? null;
    if (m.participants.includes(uid)) {
      return {tier: t, alreadyIn: true, exclude: ex, theme: th, puzzleId: pz};
    }
    if (m.status !== "lobby") throw new HttpError(409, "match already started");
    if (m.participants.length >= kMaxPlayers) throw new HttpError(409, "match is full");
    tx.update(matchRef, {
      participants: FieldValue.arrayUnion(uid),
      playerOrder: FieldValue.arrayUnion(uid),
      [`players.${uid}`]: player,
    });
    return {tier: t, alreadyIn: false, exclude: ex, theme: th, puzzleId: pz};
  });

  if (!alreadyIn) {
    // Both players race on the SAME puzzle so max words/score are identical (fair).
    const pid = await drawRackForPlayer(matchId, uid, tier, exclude, rng, theme, puzzleId);
    if (!puzzleId) await matchRef.update({usedPuzzleIds: FieldValue.arrayUnion(pid), puzzleId: pid});
  }
}

// Adds the caller to a lobby by code and writes their rack (the SAME puzzle as
// the creator's). Idempotent: re-joining returns the same matchId.
export async function joinMatch(
  uid: string,
  isGuest: boolean,
  code: string,
  rng: Rng = defaultRng,
): Promise<{matchId: string}> {
  const matchId = await lookupCode(code);
  if (!matchId) throw new HttpError(404, "unknown or closed code");
  await addParticipant(uid, isGuest, matchId, rng);
  return {matchId};
}

// --- ready / start ---------------------------------------------------------

// Sets startedAt/endsAt and moves to countdown. startedAt is a few seconds out
// so both clients run the same visual countdown, then play from startedAt.
export function applyStart(
  tx: FirebaseFirestore.Transaction,
  matchRef: FirebaseFirestore.DocumentReference,
  m: MatchData,
): void {
  const now = Date.now();
  const startedAt = now + kCountdownMs;
  const endsAt = startedAt + m.settings.durationSec * 1000;
  tx.update(matchRef, {status: "countdown", startedAt, endsAt});
}

// Toggles the caller's ready flag. When both participants are ready, transitions
// to countdown. Idempotent once the match has left the lobby.
export async function setReady(
  uid: string,
  matchId: string,
  ready: boolean,
): Promise<{ok: true; status: string}> {
  const matchRef = db.collection("matches").doc(matchId);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(matchRef);
    if (!snap.exists) throw new HttpError(404, "match not found");
    const m = snap.data() as MatchData;
    if (!m.participants.includes(uid)) throw new HttpError(403, "not a participant");
    if (m.status !== "lobby") return {ok: true as const, status: m.status};
    tx.update(matchRef, {
      [`players.${uid}.ready`]: ready,
      [`players.${uid}.lastSeen`]: Date.now(),
    });
    const allReady =
      m.participants.length >= kMaxPlayers &&
      m.participants.every((p) => (p === uid ? ready : m.players[p]?.ready ?? false));
    if (allReady) {
      applyStart(tx, matchRef, m);
      return {ok: true as const, status: "countdown"};
    }
    return {ok: true as const, status: "lobby"};
  });
}

// Creator force-start (skips waiting on the opponent's ready). Needs 2 players.
export async function startMatch(uid: string, matchId: string): Promise<{ok: true}> {
  const matchRef = db.collection("matches").doc(matchId);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(matchRef);
    if (!snap.exists) throw new HttpError(404, "match not found");
    const m = snap.data() as MatchData;
    if (m.createdBy !== uid) throw new HttpError(403, "only the creator can start");
    if (m.status !== "lobby") return {ok: true as const};
    if (m.participants.length < kMaxPlayers) throw new HttpError(409, "need an opponent to start");
    applyStart(tx, matchRef, m);
    return {ok: true as const};
  });
}

// --- leave / cancel --------------------------------------------------------

// Leaving a lobby/countdown cancels it and frees the code. Leaving an active
// match forfeits: the remaining player wins (finalize writes history + frees the
// code). No-op once finished/cancelled.
export async function leaveMatch(uid: string, matchId: string): Promise<{ok: true}> {
  const matchRef = db.collection("matches").doc(matchId);
  const snap = await matchRef.get();
  if (!snap.exists) throw new HttpError(404, "match not found");
  const m = snap.data() as MatchData;
  if (!m.participants.includes(uid)) throw new HttpError(403, "not a participant");

  if (m.status === "lobby" || m.status === "countdown") {
    await matchRef.update({status: "cancelled", [`players.${uid}.connected`]: false});
    await releaseCode(m.code);
    return {ok: true};
  }
  if (m.status === "active") {
    const other = m.participants.find((p) => p !== uid) ?? null;
    // PLAN: leaving mid-match is a forfeit (opponent wins). An alternative is to
    // finalize by wordsFound as-is; product chose forfeit for a cleaner "they
    // left, you win" result.
    await finalizeMatch(matchId, {winnerOverride: other});
    return {ok: true};
  }
  return {ok: true};
}
