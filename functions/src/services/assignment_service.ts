import {db} from "../firebase";
import {deriveAnswerKey, encryptAnswerFields} from "../crypto/answer_cipher";
import {Tier, TIER_ORDER} from "../generation/config";
import {Rng} from "../generation/random";
import {selectUnseen} from "./select_unseen";

// Read a few extra candidates so excluding already-assigned puzzles still
// leaves enough. Keeps a draw at O(n) reads instead of O(pool size).
const OVERSAMPLE = 3;

/** Random lower bound in [0,1) for the range window. Pure, for tests. */
export function pickWindow(_count: number, rng: Rng): number {
  return Math.min(0.999999, Math.max(0, rng()));
}

export interface PuzzleDoc {
  tier: string;
  rackSize: number;
  letters: string[];
  letterKey: string;
  anchor: string;
  answers: {word: string; length: number; definition: string | null}[];
  answerCount: number;
}

// Wire form sent to clients: answers are encrypted per-user. Only the length
// stays in the clear (the board renders blanks from it).
export interface WireAnswer {
  length: number;
  enc: string;
}
export type WirePuzzle = Omit<PuzzleDoc, "answers"> & {answers: WireAnswer[]};

export interface DrawTierResult {
  requested: number;
  assigned: number;
  puzzles: WirePuzzle[];
}

export interface DrawResult {
  byTier: Partial<Record<Tier, DrawTierResult>>;
  shortfall: boolean;
}

// Encrypts a puzzle's answers with the caller's per-user key. Derive the key
// once per request and reuse it across the batch.
export function encryptPuzzle(key: Buffer, p: PuzzleDoc): WirePuzzle {
  return {...p, answers: p.answers.map((a) => encryptAnswerFields(key, a))};
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

async function drawTierCandidates(
  tier: Tier,
  n: number,
  assignedIds: Set<string>,
  rng: Rng,
): Promise<string[]> {
  const want = n * OVERSAMPLE;
  const start = pickWindow(n, rng);
  const col = db.collection("puzzles").where("tier", "==", tier);
  // Forward window from a random point.
  const forward = await col
    .where("random", ">=", start)
    .orderBy("random")
    .limit(want)
    .select()
    .get();
  const ids = forward.docs.map((d) => d.id).filter((id) => !assignedIds.has(id));
  if (ids.length >= n) return ids.slice(0, n);
  // Wrap around: read from the start of the tier to top up.
  const wrap = await col
    .where("random", "<", start)
    .orderBy("random")
    .limit(want)
    .select()
    .get();
  for (const d of wrap.docs) {
    if (ids.length >= n) break;
    if (!assignedIds.has(d.id)) ids.push(d.id);
  }
  if (ids.length >= n) return ids.slice(0, n);

  // Fallback: a Firestore range filter SKIPS documents that lack the field, so
  // any puzzle written before `random` existed (or before the backfill script
  // ran) is invisible to the windowed query above. Without this scan a deploy
  // that lands ahead of the backfill would serve zero puzzles. Costs a full
  // tier read, but only when the window came up short.
  const all = await col.select().get();
  const {chosen} = selectUnseen(all.docs.map((d) => d.id), assignedIds, n, rng);
  return chosen;
}

interface DrawRecordTier {
  requested: number;
  puzzleIds: string[];
}

async function replayDraw(
  key: Buffer,
  tiers: Record<string, DrawRecordTier>,
): Promise<DrawResult> {
  const byTier: Partial<Record<Tier, DrawTierResult>> = {};
  let shortfall = false;
  for (const tier of Object.keys(tiers) as Tier[]) {
    const rec = tiers[tier];
    const puzzles = (await fetchPuzzles(rec.puzzleIds)).map((p) => encryptPuzzle(key, p));
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
  const key = deriveAnswerKey(uid);
  const drawRef = db.collection("users").doc(uid).collection("draws").doc(idempotencyKey);
  const existing = await drawRef.get();
  if (existing.exists) {
    const tiers = (existing.data()?.tiers ?? {}) as Record<string, DrawRecordTier>;
    return replayDraw(key, tiers);
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
    const chosen = await drawTierCandidates(tier, n, assignedIds, rng);
    const sf = n - chosen.length;
    chosen.forEach((id) => {
      assignedIds.add(id);
      chosenAll.push({id, tier});
    });
    if (sf > 0) shortfall = true;
    const puzzles = (await fetchPuzzles(chosen)).map((p) => encryptPuzzle(key, p));
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

export async function getAssigned(
  uid: string,
  status: "incomplete" | "completed" | "all",
): Promise<{puzzles: (WirePuzzle & {completed: boolean})[]}> {
  const key = deriveAnswerKey(uid);
  const col = db.collection("users").doc(uid).collection("assignments");
  let snap;
  if (status === "incomplete") {
    snap = await col.where("completed", "==", false).get();
  } else if (status === "completed") {
    snap = await col.where("completed", "==", true).get();
  } else {
    snap = await col.get();
  }
  const completedById = new Map(
    snap.docs.map((d) => [d.id, (d.data().completed as boolean) ?? false]),
  );
  const puzzles = await fetchPuzzles([...completedById.keys()]);
  return {
    puzzles: puzzles.map((p) => ({
      ...encryptPuzzle(key, p),
      completed: completedById.get(p.letterKey) ?? false,
    })),
  };
}
