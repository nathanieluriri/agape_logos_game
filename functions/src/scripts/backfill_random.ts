import {db} from "../firebase";

/**
 * One-off: stamp a uniform `random` field on every puzzle that lacks one, so the
 * new random-window draw works on the already-seeded pool. Idempotent: skips
 * docs that already have `random`. Run with:
 *   GOOGLE_APPLICATION_CREDENTIALS=... GCLOUD_PROJECT=agape-logos \
 *     node lib/scripts/backfill_random.js
 */
async function main(): Promise<void> {
  const snap = await db.collection("puzzles").get();
  let updated = 0;
  let batch = db.batch();
  let inBatch = 0;
  for (const doc of snap.docs) {
    if (typeof doc.data().random === "number") continue;
    batch.update(doc.ref, {random: Math.random()});
    inBatch++;
    updated++;
    if (inBatch >= 400) {
      await batch.commit();
      batch = db.batch();
      inBatch = 0;
    }
  }
  if (inBatch > 0) await batch.commit();
  // eslint-disable-next-line no-console
  console.log(`backfilled random on ${updated} puzzles`);
}

main().catch((e) => {
  // eslint-disable-next-line no-console
  console.error(e);
  process.exit(1);
});
