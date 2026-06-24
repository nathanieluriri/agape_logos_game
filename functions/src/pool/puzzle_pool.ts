import {db} from "../firebase";
import {Tier, TIER_ORDER} from "../generation/config";
import {Puzzle} from "../generation/puzzle";

const COLLECTION = "puzzles";

export async function loadExistingLetterKeys(): Promise<Set<string>> {
  const snap = await db.collection(COLLECTION).select().get();
  return new Set(snap.docs.map((d) => d.id));
}

export async function writePuzzles(puzzles: Puzzle[]): Promise<void> {
  const CHUNK = 500;
  for (let i = 0; i < puzzles.length; i += CHUNK) {
    const batch = db.batch();
    for (const p of puzzles.slice(i, i + CHUNK)) {
      batch.set(db.collection(COLLECTION).doc(p.letterKey), {
        ...p,
        generatedAt: Date.now(),
      });
    }
    await batch.commit();
  }
}

export interface PoolStats {
  total: number;
  perTier: Record<Tier, number>;
}

export async function getStats(): Promise<PoolStats> {
  const perTier = {easy: 0, medium: 0, hard: 0, expert: 0} as Record<Tier, number>;
  let total = 0;
  for (const tier of TIER_ORDER) {
    const agg = await db.collection(COLLECTION).where("tier", "==", tier).count().get();
    perTier[tier] = agg.data().count;
    total += perTier[tier];
  }
  return {total, perTier};
}

export async function updateLibraryMeta(stats: PoolStats): Promise<void> {
  await db.doc("meta/puzzleLibrary").set({
    totalCount: stats.total,
    perTier: stats.perTier,
    updatedAt: Date.now(),
  });
}
