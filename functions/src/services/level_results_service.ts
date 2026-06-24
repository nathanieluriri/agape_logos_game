import {FieldValue} from "firebase-admin/firestore";
import {db} from "../firebase";
import {LevelResultBody} from "../schemas/level_results";

// Idempotent write: the idempotency key is the document id, so replays
// overwrite the same doc under users/{uid}/levelResults.
export async function saveLevelResult(
  uid: string,
  idempotencyKey: string,
  levelId: number,
  body: LevelResultBody,
): Promise<void> {
  await db
    .collection("users").doc(uid)
    .collection("levelResults").doc(idempotencyKey)
    .set({
      levelId,
      score: body.score,
      completedAt: body.completedAt,
      uid,
      syncedAt: FieldValue.serverTimestamp(),
    });
}
