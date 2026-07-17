import {db} from "../firebase";

// Minimal starter themes. wordsByDifficulty anchors are matched against the pool
// to TAG existing puzzles (no new generation). Extend this list later.
const THEMES = [
  {id: "nature", name: "Nature", words: ["SEA", "FERN", "LAKE", "TREE", "LEAF", "FOREST", "RIVER"]},
  {id: "food", name: "Food", words: ["TEA", "RICE", "CAKE", "BEAN", "BREAD", "APPLE", "HONEY"]},
];

// Idempotent: upserts each theme doc, then tags every pool puzzle whose anchor is
// in the theme's word list by adding the themeId to a `themes` array.
async function main(): Promise<void> {
  for (const t of THEMES) {
    await db.collection("themes").doc(t.id).set({
      id: t.id, name: t.name,
      wordsByDifficulty: {easy: [], medium: [], hard: []}, // shape reserved for future themed generation
      words: t.words,
    }, {merge: true});
  }
  const pool = await db.collection("puzzles").get();
  let tagged = 0;
  let batch = db.batch();
  let inBatch = 0;
  for (const doc of pool.docs) {
    const anchor = ((doc.data().anchor as string) ?? "").toUpperCase();
    const themeIds = THEMES.filter((t) => t.words.includes(anchor)).map((t) => t.id);
    if (themeIds.length === 0) continue;
    // FieldValue.arrayUnion via admin - import lazily to keep the top clean.
    const {FieldValue} = await import("firebase-admin/firestore");
    batch.update(doc.ref, {themes: FieldValue.arrayUnion(...themeIds)});
    inBatch++; tagged++;
    if (inBatch >= 400) { await batch.commit(); batch = db.batch(); inBatch = 0; }
  }
  if (inBatch > 0) await batch.commit();
  // eslint-disable-next-line no-console
  console.log(`seeded ${THEMES.length} themes; tagged ${tagged} puzzles`);
}

main().catch((e) => { /* eslint-disable-next-line no-console */ console.error(e); process.exit(1); });
