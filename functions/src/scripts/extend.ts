import {TIERS, TIER_ORDER, Tier} from "../generation/config";
import {runGeneration, defaultDeps, TierPlan} from "./generate";

// Splits N new puzzles across tiers by the pool-target ratio.
function splitByRatio(total: number): Record<Tier, number> {
  const totalTarget = TIER_ORDER.reduce((acc, t) => acc + TIERS[t].poolTarget, 0);
  const out = {easy: 0, medium: 0, hard: 0, expert: 0} as Record<Tier, number>;
  let assigned = 0;
  TIER_ORDER.forEach((tier, i) => {
    if (i === TIER_ORDER.length - 1) {
      out[tier] = total - assigned; // remainder to the last tier
    } else {
      out[tier] = Math.round((TIERS[tier].poolTarget / totalTarget) * total);
      assigned += out[tier];
    }
  });
  return out;
}

async function main(): Promise<void> {
  // Count comes from an env var, not a CLI arg: `npm run extend` wraps the node
  // script inside `firebase emulators:exec "..."`, and `npm run extend -- N`
  // appends N to emulators:exec, never reaching this script. An env var crosses
  // that boundary cleanly. Production direct-invocation also reads it.
  const n = Number(process.env.PUZZLE_EXTEND_COUNT);
  if (!Number.isInteger(n) || n <= 0) {
    throw new Error("usage: PUZZLE_EXTEND_COUNT=<positive integer> npm run extend");
  }
  const split = splitByRatio(n);
  const plans: TierPlan[] = TIER_ORDER.map((tier) => ({tier, count: split[tier]}));
  const report = await runGeneration(plans, defaultDeps());
  // eslint-disable-next-line no-console
  console.log("extend complete", JSON.stringify(report.perTier), "written", report.written);
}

main().then(
  () => process.exit(0),
  (err) => {
    // eslint-disable-next-line no-console
    console.error(err);
    process.exit(1);
  },
);
