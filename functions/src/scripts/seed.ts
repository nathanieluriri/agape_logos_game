// Production seeding (real project, not the emulator):
//   npm run build
//   GOOGLE_APPLICATION_CREDENTIALS=<service-account.json> \
//     GCLOUD_PROJECT=agape-logos node lib/scripts/seed.js
// The emulator-wrapped `npm run seed` is for local development only.

import {TIERS, TIER_ORDER} from "../generation/config";
import {getStats} from "../pool/puzzle_pool";
import {runGeneration, defaultDeps, TierPlan} from "./generate";

// Tops the pool up toward each tier's poolTarget (idempotent: already-present
// puzzles count, so re-running only fills the remainder).
async function main(): Promise<void> {
  const stats = await getStats();
  const plans: TierPlan[] = TIER_ORDER.map((tier) => ({
    tier,
    count: Math.max(0, TIERS[tier].poolTarget - stats.perTier[tier]),
  }));
  const report = await runGeneration(plans, defaultDeps());
  // eslint-disable-next-line no-console
  console.log("seed complete", JSON.stringify(report.perTier), "written", report.written);
}

main().then(
  () => process.exit(0),
  (err) => {
    // eslint-disable-next-line no-console
    console.error(err);
    process.exit(1);
  },
);
