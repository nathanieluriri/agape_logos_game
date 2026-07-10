import {FieldValue} from "firebase-admin/firestore";
import {db} from "../firebase";
import {wordScore} from "./match_scoring";
import {settleMatch} from "./match_finalize";
import {HttpError} from "../middleware/http_error";
import type {MatchData} from "./match_types";

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
    const rack = rackSnap.data() as {letterKey: string; foundWords: string[]} | undefined;
    if (!rack) throw new HttpError(409, "no rack for player");

    const now = Date.now();
    const curScore = m.players[uid]?.score ?? 0;
    const curWords = m.players[uid]?.wordsFound ?? 0;
    const playable = m.status === "active" && now >= m.startedAt && now < m.endsAt;
    if (!playable) return {accepted: false, score: curScore, wordsFound: curWords, reason: "not_active"};
    if (rack.foundWords.includes(word)) {
      return {accepted: false, score: curScore, wordsFound: curWords, reason: "duplicate"};
    }

    // Validate against the pool puzzle's PLAINTEXT answers, held server-side.
    // The rack's letterKey is the puzzles/{letterKey} doc id (verified: doc id
    // === letterKey). The client only ever holds encrypted answers.
    const puzzleSnap = await tx.get(db.collection("puzzles").doc(rack.letterKey));
    const answers = (puzzleSnap.data()?.answers ?? []) as {word: string}[];
    const valid = answers.some((a) => a.word.toUpperCase() === word);
    if (!valid) return {accepted: false, score: curScore, wordsFound: curWords, reason: "invalid"};

    const pts = wordScore(word);
    tx.update(rackRef, {foundWords: FieldValue.arrayUnion(word)});
    tx.update(matchRef, {
      [`players.${uid}.score`]: FieldValue.increment(pts),
      [`players.${uid}.wordsFound`]: FieldValue.increment(1),
      [`players.${uid}.lastSeen`]: now,
    });
    return {accepted: true, score: curScore + pts, wordsFound: curWords + 1};
  });
}
