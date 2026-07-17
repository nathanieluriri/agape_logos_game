import {FieldValue} from "firebase-admin/firestore";
import {db} from "../firebase";
import {PuzzleResultBody} from "../schemas/puzzles";
import {DEFAULT_PROFILE} from "../schemas/profile";

// Server-authoritative coin award for a solved puzzle: a flat bonus plus the
// level score. Mirrors the client's optimistic estimate in game_controller.dart
// (_coinsFor) so the optimistic UI matches what reconciles back from GET /me.
export function coinsForResult(score: number): number {
  return 10 + score;
}

// Records a puzzle result and applies its rewards exactly once.
//
// The whole thing runs in a transaction keyed off puzzleResults/{idempotencyKey}:
//   - First delivery: write the result doc, flip the assignment to completed,
//     and increment the profile wallet (coins) + totalScore, bumping
//     highestLevel when the client sent a level. This is the ONLY place coins
//     are minted, so the balance is server-owned and unspoofable.
//   - Replay (at-least-once sync re-sends the same idempotency key): the result
//     doc already exists, so rewards are NOT re-applied. We still re-assert the
//     assignment as completed (idempotent) to heal a partial earlier write.
export async function savePuzzleResult(
  uid: string,
  idempotencyKey: string,
  puzzleId: string,
  body: PuzzleResultBody,
): Promise<void> {
  const userRef = db.collection("users").doc(uid);
  const resultRef = userRef.collection("puzzleResults").doc(idempotencyKey);
  const assignmentRef = userRef.collection("assignments").doc(puzzleId);

  await db.runTransaction(async (tx) => {
    // All reads must precede writes inside a Firestore transaction.
    const resultSnap = await tx.get(resultRef);
    const alreadyApplied = resultSnap.exists;
    const profileSnap = alreadyApplied ? null : await tx.get(userRef);

    // Assignment completion is idempotent; assert it on every delivery so a
    // recovered/out-of-order client never loses the "completed" flag.
    tx.set(
      assignmentRef,
      {puzzleId, completed: true, completedAt: body.completedAt},
      {merge: true},
    );

    if (alreadyApplied) return;

    // First delivery: persist the result and mint the rewards.
    tx.set(resultRef, {
      puzzleId,
      score: body.score,
      completedAt: body.completedAt,
      uid,
      syncedAt: FieldValue.serverTimestamp(),
    });

    // Provision the profile if this is the user's very first server write, then
    // apply the increments. highestLevel is a monotonic max, not an increment.
    const existing = (profileSnap?.data() ?? {}) as Record<string, unknown>;
    const currentHighest =
      (existing.highestLevel as number) ?? DEFAULT_PROFILE.highestLevel;
    const nextHighest =
      body.level === undefined
        ? currentHighest
        : Math.max(currentHighest, body.level);

    const rewards: Record<string, unknown> = {
      coins: FieldValue.increment(coinsForResult(body.score)),
      totalScore: FieldValue.increment(body.score),
      highestLevel: nextHighest,
      updatedAt: FieldValue.serverTimestamp(),
    };
    if (!profileSnap?.exists) {
      rewards.uid = uid;
      rewards.createdAt = FieldValue.serverTimestamp();
      rewards.displayName = DEFAULT_PROFILE.displayName;
      rewards.avatarId = DEFAULT_PROFILE.avatarId;
      rewards.locale = DEFAULT_PROFILE.locale;
      rewards.soundEnabled = DEFAULT_PROFILE.soundEnabled;
      rewards.musicEnabled = DEFAULT_PROFILE.musicEnabled;
    }
    tx.set(userRef, rewards, {merge: true});
  });
}
