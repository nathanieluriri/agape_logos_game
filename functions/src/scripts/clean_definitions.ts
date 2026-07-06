// Enforces the rule that every answer carries a definition across the puzzles
// ALREADY in Firestore. Any puzzle with even one missing or blank definition is
// deleted outright (reject the whole rack); puzzles where every answer is
// defined are left unchanged. Uses only the definitions already stored on each
// puzzle doc, so it needs no dictionary API access.
//
// Local emulator:  npm run clean:defs
// Production (real project, not the emulator):
//   npm run build
//   GOOGLE_APPLICATION_CREDENTIALS=<service-account.json> \
//     GCLOUD_PROJECT=agape-logos node lib/scripts/clean_definitions.js

import {db} from "../firebase";
import {Puzzle, requireAllDefined} from "../generation/puzzle";
import {getStats, updateLibraryMeta} from "../pool/puzzle_pool";

const COLLECTION = "puzzles";

async function main(): Promise<void> {
  const snap = await db.collection(COLLECTION).get();
  const report = {
    scanned: snap.size,
    unchanged: 0,
    deleted: 0,
    wordsRemoved: 0,
  };

  // Firestore caps a batch at 500 writes; commit in chunks well under that.
  const CHUNK = 400;
  let batch = db.batch();
  let ops = 0;

  for (const doc of snap.docs) {
    const puzzle = doc.data() as Puzzle;
    const clean = requireAllDefined(puzzle);

    if (clean === null) {
      batch.delete(doc.ref);
      report.deleted++;
      report.wordsRemoved += puzzle.answers.length;
      ops++;
    } else {
      report.unchanged++;
      continue;
    }

    if (ops >= CHUNK) {
      await batch.commit();
      batch = db.batch();
      ops = 0;
    }
  }

  if (ops > 0) await batch.commit();

  await updateLibraryMeta(await getStats());
  // eslint-disable-next-line no-console
  console.log("clean:defs complete", JSON.stringify(report));
}

main().then(
  () => process.exit(0),
  (err) => {
    // eslint-disable-next-line no-console
    console.error(err);
    process.exit(1);
  },
);
