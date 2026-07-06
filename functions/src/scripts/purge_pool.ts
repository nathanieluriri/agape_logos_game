// Deletes the entire puzzle pool so a regenerated pool fully replaces (not
// merges with) the old one. writePuzzles upserts by letterKey and never deletes,
// so old repeated-letter / >5-answer puzzles must be cleared explicitly first.
//
// Local emulator:  npm run purge:pool
// Production (real project, not the emulator):
//   npm run build
//   GOOGLE_APPLICATION_CREDENTIALS=<service-account.json> \
//     GCLOUD_PROJECT=agape-logos node lib/scripts/purge_pool.js

import {db} from "../firebase";

const COLLECTION = "puzzles";

export async function purgePool(): Promise<{deleted: number}> {
  const snap = await db.collection(COLLECTION).select().get();
  let deleted = 0;
  const CHUNK = 400;
  let batch = db.batch();
  let ops = 0;
  for (const doc of snap.docs) {
    batch.delete(doc.ref);
    ops++;
    deleted++;
    if (ops >= CHUNK) {
      await batch.commit();
      batch = db.batch();
      ops = 0;
    }
  }
  if (ops > 0) await batch.commit();
  await db.doc("meta/puzzleLibrary").delete();
  return {deleted};
}

// Executed directly as a script (skipped when imported by a test).
if (require.main === module) {
  purgePool().then(
    (r) => {
      // eslint-disable-next-line no-console
      console.log("purge:pool complete", JSON.stringify(r));
      process.exit(0);
    },
    (err) => {
      // eslint-disable-next-line no-console
      console.error(err);
      process.exit(1);
    },
  );
}
