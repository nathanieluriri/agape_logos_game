import {db} from "../firebase";
import {Tier, TIER_ORDER} from "../generation/config";
import {Rng} from "../generation/random";
import {selectUnseen} from "./select_unseen";

export interface PuzzleDoc {
  tier: string;
  rackSize: number;
  letters: string[];
  letterKey: string;
  anchor: string;
  answers: {word: string; length: number; definition: string | null}[];
  answerCount: number;
}

export interface DrawTierResult {
  requested: number;
  assigned: number;
  puzzles: PuzzleDoc[];
}

export interface DrawResult {
  byTier: Partial<Record<Tier, DrawTierResult>>;
  shortfall: boolean;
}

const defaultRng: Rng = () => Math.random();

function toPuzzle(data: Record<string, unknown>): PuzzleDoc {
  return {
    tier: data.tier as string,
    rackSize: data.rackSize as number,
    letters: data.letters as string[],
    letterKey: data.letterKey as string,
    anchor: data.anchor as string,
    answers: data.answers as PuzzleDoc["answers"],
    answerCount: data.answerCount as number,
  };
}

export async function fetchPuzzles(ids: string[]): Promise<PuzzleDoc[]> {
  if (ids.length === 0) return [];
  const refs = ids.map((id) => db.collection("puzzles").doc(id));
  const snaps = await db.getAll(...refs);
  return snaps
    .filter((s) => s.exists)
    .map((s) => toPuzzle(s.data() as Record<string, unknown>));
}

interface DrawRecordTier {
  requested: number;
  puzzleIds: string[];
}

async function replayDraw(tiers: Record<string, DrawRecordTier>): Promise<DrawResult> {
  const byTier: Partial<Record<Tier, DrawTierResult>> = {};
  let shortfall = false;
  for (const tier of Object.keys(tiers) as Tier[]) {
    const rec = tiers[tier];
    const puzzles = await fetchPuzzles(rec.puzzleIds);
    byTier[tier] = {requested: rec.requested, assigned: rec.puzzleIds.length, puzzles};
    if (rec.puzzleIds.length < rec.requested) shortfall = true;
  }
  return {byTier, shortfall};
}

// Draw unseen puzzles per requested tier. Idempotent on idempotencyKey: a replay
// returns the originally assigned batch and assigns nothing new. Mutates the
// user's assignments ledger (one doc per drawn puzzle, doc id = puzzleId).
export async function draw(
  uid: string,
  counts: Partial<Record<Tier, number>>,
  idempotencyKey: string,
  rng: Rng = defaultRng,
): Promise<DrawResult> {
  const drawRef = db.collection("users").doc(uid).collection("draws").doc(idempotencyKey);
  const existing = await drawRef.get();
  if (existing.exists) {
    const tiers = (existing.data()?.tiers ?? {}) as Record<string, DrawRecordTier>;
    return replayDraw(tiers);
  }

  const assignedSnap = await db
    .collection("users").doc(uid).collection("assignments").select().get();
  const assignedIds = new Set(assignedSnap.docs.map((d) => d.id));

  const byTier: Partial<Record<Tier, DrawTierResult>> = {};
  const tiersRecord: Record<string, DrawRecordTier> = {};
  const chosenAll: {id: string; tier: Tier}[] = [];
  let shortfall = false;

  for (const tier of TIER_ORDER) {
    const n = counts[tier] ?? 0;
    if (n <= 0) continue;
    const tierSnap = await db.collection("puzzles").where("tier", "==", tier).select().get();
    const tierIds = tierSnap.docs.map((d) => d.id);
    const {chosen, shortfall: sf} = selectUnseen(tierIds, assignedIds, n, rng);
    chosen.forEach((id) => {
      assignedIds.add(id);
      chosenAll.push({id, tier});
    });
    if (sf > 0) shortfall = true;
    const puzzles = await fetchPuzzles(chosen);
    byTier[tier] = {requested: n, assigned: chosen.length, puzzles};
    tiersRecord[tier] = {requested: n, puzzleIds: chosen};
  }

  const batch = db.batch();
  const now = Date.now();
  for (const {id, tier} of chosenAll) {
    batch.set(db.collection("users").doc(uid).collection("assignments").doc(id), {
      puzzleId: id, tier, assignedAt: now, completed: false, completedAt: null,
    });
  }
  batch.set(drawRef, {tiers: tiersRecord, at: now});
  await batch.commit();

  if (shortfall) {
    // eslint-disable-next-line no-console
    console.warn(`draw shortfall for uid=${uid}`, JSON.stringify(tiersRecord));
  }
  return {byTier, shortfall};
}
