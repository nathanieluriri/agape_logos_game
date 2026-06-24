import {FieldValue} from "firebase-admin/firestore";
import {db} from "../firebase";
import {PuzzleResultBody} from "../schemas/puzzles";

// Atomic batch: record the result under puzzleResults/{idempotencyKey} and flip
// the user's assignment for this puzzle to completed (merge creates it if the
// puzzle was never assigned, so a recovered/out-of-order client never loses a
// result). Replays overwrite the same docs (idempotent).
export async function savePuzzleResult(
  uid: string,
  idempotencyKey: string,
  puzzleId: string,
  body: PuzzleResultBody,
): Promise<void> {
  const batch = db.batch();
  const resultRef = db
    .collection("users").doc(uid).collection("puzzleResults").doc(idempotencyKey);
  batch.set(resultRef, {
    puzzleId,
    score: body.score,
    completedAt: body.completedAt,
    uid,
    syncedAt: FieldValue.serverTimestamp(),
  });
  const assignmentRef = db
    .collection("users").doc(uid).collection("assignments").doc(puzzleId);
  batch.set(
    assignmentRef,
    {puzzleId, completed: true, completedAt: body.completedAt},
    {merge: true},
  );
  await batch.commit();
}
