// Exports a small, rule-compliant starter pack from the (regenerated) Firestore
// pool into the bundled offline asset. Starter puzzles are plaintext and local-
// only: their ids use the `starter-` prefix so results never enqueue for sync.
//
// Local emulator:  npm run export:starter
// Production:      GCLOUD_PROJECT=agape-logos node lib/scripts/export_starter_pack.js

import * as fs from "fs";
import * as path from "path";
import {TIER_ORDER} from "../generation/config";
// NOTE: `../firebase` is imported lazily inside main() so this module stays
// side-effect-free for the pure buildStarterPack unit test (no admin init).

const STARTER_VERSION = 2;
const PER_TIER = 6; // easy/medium/hard drawn by the client; keep the pack small.
const OUT_FILE = path.resolve(__dirname, "../../../assets/puzzles/starter_pack.json");

interface PoolAnswer {word: string; length: number; definition: string | null}
interface PoolDoc {
  tier: string; rackSize: number; letters: string[]; anchor: string;
  answerCount: number; answers: PoolAnswer[];
}
interface StarterPuzzle {
  tier: string; rackSize: number; letters: string[]; letterKey: string;
  anchor: string; answerCount: number; answers: PoolAnswer[];
}

export function buildStarterPack(
  pool: PoolDoc[],
  perTier: number,
): {version: number; puzzles: StarterPuzzle[]} {
  const puzzles: StarterPuzzle[] = [];
  for (const tier of ["easy", "medium", "hard"]) {
    const forTier = pool.filter((p) => p.tier === tier).slice(0, perTier);
    forTier.forEach((p, i) => {
      const n = String(i + 1).padStart(2, "0");
      puzzles.push({
        tier: p.tier,
        rackSize: p.rackSize,
        letters: p.letters,
        letterKey: `starter-${tier}-${n}`,
        anchor: p.anchor,
        answerCount: p.answerCount,
        answers: p.answers,
      });
    });
  }
  return {version: STARTER_VERSION, puzzles};
}

async function main(): Promise<void> {
  const {db} = await import("../firebase");
  const pool: PoolDoc[] = [];
  for (const tier of TIER_ORDER) {
    const snap = await db.collection("puzzles").where("tier", "==", tier).limit(PER_TIER).get();
    for (const d of snap.docs) pool.push(d.data() as PoolDoc);
  }
  const pack = buildStarterPack(pool, PER_TIER);
  fs.writeFileSync(OUT_FILE, JSON.stringify(pack, null, 2) + "\n", "utf8");
  // eslint-disable-next-line no-console
  console.log("export:starter complete", pack.puzzles.length, "->", OUT_FILE);
}

if (require.main === module) {
  main().then(
    () => process.exit(0),
    (err) => {
      // eslint-disable-next-line no-console
      console.error(err);
      process.exit(1);
    },
  );
}
