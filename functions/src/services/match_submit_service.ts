import {FieldValue} from "firebase-admin/firestore";
import {db} from "../firebase";
import {wordScore} from "./match_scoring";
import {settleMatch} from "./match_finalize";
import {HttpError} from "../middleware/http_error";
import type {ActiveEffect, MatchData} from "./match_types";

// Drops expired entries. expiresAt === 0 means "armed until consumed" and
// never expires by time alone.
function pruneEffects(list: ActiveEffect[] | undefined, now: number): ActiveEffect[] {
  return (list ?? []).filter((e) => e.expiresAt === 0 || e.expiresAt > now);
}

export interface SubmitResult {
  accepted: boolean;
  score: number;
  wordsFound: number;
  reason?: string;
}

// Validates a submitted word against the caller's PRIVATE rack, scores it, and
// updates players[uid].score/wordsFound + the rack's foundWords. Fully
// server-authoritative (anti-cheat): the client never sends a score. Idempotent
// per (uid, normalizedWord): a word already found is a no-op.
export async function submitWord(
  uid: string,
  matchId: string,
  rawWord: string,
): Promise<SubmitResult> {
  // Advance the clock first: a submit after endsAt must not score (it finalizes).
  const settled = await settleMatch(matchId);
  if (!settled) throw new HttpError(404, "match not found");
  if (!settled.participants.includes(uid)) throw new HttpError(403, "not a participant");

  const word = rawWord.trim().toUpperCase();
  const matchRef = db.collection("matches").doc(matchId);
  const rackRef = matchRef.collection("racks").doc(uid);

  return db.runTransaction<SubmitResult>(async (tx) => {
    // All reads first (Firestore transaction rule).
    const mSnap = await tx.get(matchRef);
    const rackSnap = await tx.get(rackRef);
    const m = mSnap.data() as MatchData;
    const rack = rackSnap.data() as
      {letterKey: string; foundWords: string[]; answerCount?: number} | undefined;
    if (!rack) throw new HttpError(409, "no rack for player");

    const now = Date.now();
    const curScore = m.players[uid]?.score ?? 0;
    const curWords = m.players[uid]?.wordsFound ?? 0;
    // A time_boost extends THIS player's personal deadline past the shared
    // endsAt; everyone else still stops at endsAt.
    const myBonus = m.players[uid]?.endsAtBonusMs ?? 0;
    const playable = m.status === "active" && now >= m.startedAt && now < m.endsAt + myBonus;
    if (!playable) return {accepted: false, score: curScore, wordsFound: curWords, reason: "not_active"};
    if (rack.foundWords.includes(word)) {
      return {accepted: false, score: curScore, wordsFound: curWords, reason: "duplicate"};
    }

    const myEffects = pruneEffects(m.activeEffects?.[uid], now);
    if (myEffects.some((e) => {
      if (e.kind !== "letter_freeze") return false;
      const letter = e.payload.letter;
      return typeof letter === "string" && letter.length > 0 && word.includes(letter);
    })) {
      return {accepted: false, score: curScore, wordsFound: curWords, reason: "frozen"};
    }

    // Validate against the pool puzzle's PLAINTEXT answers, held server-side.
    // The rack's letterKey is the puzzles/{letterKey} doc id (verified: doc id
    // === letterKey). The client only ever holds encrypted answers.
    const puzzleSnap = await tx.get(db.collection("puzzles").doc(rack.letterKey));
    const answers = (puzzleSnap.data()?.answers ?? []) as {word: string}[];
    const valid = answers.some((a) => a.word.toUpperCase() === word);
    if (!valid) return {accepted: false, score: curScore, wordsFound: curWords, reason: "invalid"};

    const mult = myEffects.some((e) => e.kind === "double_points") ? 2 : 1;
    const pts = wordScore(word) * mult;
    // finishedAt marks finding the LAST answer; settleMatch ends the match early
    // once every participant is done. lastWordAt is the speed tiebreak.
    const done = rack.foundWords.length + 1 >= (rack.answerCount ?? Number.MAX_SAFE_INTEGER);
    tx.update(rackRef, {foundWords: FieldValue.arrayUnion(word)});
    tx.update(matchRef, {
      [`players.${uid}.score`]: FieldValue.increment(pts),
      [`players.${uid}.wordsFound`]: FieldValue.increment(1),
      [`players.${uid}.lastWordAt`]: now,
      ...(done ? {[`players.${uid}.finishedAt`]: now} : {}),
      [`players.${uid}.lastSeen`]: now,
    });
    return {accepted: true, score: curScore + pts, wordsFound: curWords + 1};
  });
}
