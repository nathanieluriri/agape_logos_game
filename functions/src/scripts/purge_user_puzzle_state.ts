// Clears every user's puzzle-assignment ledger so, after the pool is replaced,
// all players draw fresh from the new pool. Deletes only the `assignments` and
// `draws` subcollections; coins, highestLevel, totalScore, and puzzleResults are
// left untouched.
//
// Local emulator:  npm run purge:userstate
// Production (real project, not the emulator):
//   npm run build
//   GOOGLE_APPLICATION_CREDENTIALS=<service-account.json> \
//     GCLOUD_PROJECT=agape-logos node lib/scripts/purge_user_puzzle_state.js

import {db} from "../firebase";

async function deleteSubcollection(
  userRef: FirebaseFirestore.DocumentReference,
  name: string,
): Promise<number> {
  const snap = await userRef.collection(name).select().get();
  let ops = 0;
  const CHUNK = 400;
  let batch = db.batch();
  let n = 0;
  for (const doc of snap.docs) {
    batch.delete(doc.ref);
    ops++;
    n++;
    if (ops >= CHUNK) {
      await batch.commit();
      batch = db.batch();
      ops = 0;
    }
  }
  if (ops > 0) await batch.commit();
  return n;
}

export async function purgeUserPuzzleState(): Promise<{
  users: number;
  assignments: number;
  draws: number;
}> {
  const users = await db.collection("users").select().get();
  let assignments = 0;
  let draws = 0;
  for (const user of users.docs) {
    assignments += await deleteSubcollection(user.ref, "assignments");
    draws += await deleteSubcollection(user.ref, "draws");
  }
  return {users: users.size, assignments, draws};
}

if (require.main === module) {
  purgeUserPuzzleState().then(
    (r) => {
      // eslint-disable-next-line no-console
      console.log("purge:userstate complete", JSON.stringify(r));
      process.exit(0);
    },
    (err) => {
      // eslint-disable-next-line no-console
      console.error(err);
      process.exit(1);
    },
  );
}
