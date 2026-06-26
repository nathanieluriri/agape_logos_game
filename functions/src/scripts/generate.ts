import {
  Tier,
  COMMON_FREQUENCY_CUTOFF,
  DEFINITION_CONCURRENCY,
  DEFINITION_MAX_RETRIES,
  GEN_VERSION,
  VALIDITY_FILE,
  FREQUENCY_FILE,
  DEFINITIONS_CACHE_FILE,
} from "../generation/config";
import {WordData, loadWordDataFromFiles} from "../generation/word_data";
import {AnagramIndex, buildAnagramIndex} from "../generation/anagram_index";
import {generateTierBatch, RawPuzzle} from "../generation/generator";
import {attachDefinitions} from "../generation/puzzle";
import {
  FetchFn,
  DefinitionCache,
  loadDefinitionCache,
  saveDefinitionCache,
  resolveDefinitions,
  dictionaryApiFetch,
} from "../generation/definitions";
import {Rng, mulberry32} from "../generation/random";
import {
  loadExistingLetterKeys,
  writePuzzles,
  getStats,
  updateLibraryMeta,
} from "../pool/puzzle_pool";

export interface GenerateDeps {
  wordData: WordData;
  index: AnagramIndex;
  fetchFn: FetchFn;
  cache: DefinitionCache;
  cachePath: string;
  concurrency: number;
  genVersion: number;
  rng: Rng;
}

export interface TierPlan {
  tier: Tier;
  count: number;
}

export interface RunReport {
  written: number;
  perTier: Record<Tier, {written: number; shortfall: number}>;
}

export async function runGeneration(
  plans: TierPlan[],
  deps: GenerateDeps,
): Promise<RunReport> {
  const existingKeys = await loadExistingLetterKeys();
  const perTier = {
    easy: {written: 0, shortfall: 0},
    medium: {written: 0, shortfall: 0},
    hard: {written: 0, shortfall: 0},
    expert: {written: 0, shortfall: 0},
  } as RunReport["perTier"];

  const raw: RawPuzzle[] = [];
  for (const plan of plans) {
    if (plan.count <= 0) continue;
    const res = generateTierBatch({
      tier: plan.tier,
      count: plan.count,
      wordData: deps.wordData,
      index: deps.index,
      existingKeys,
      rng: deps.rng,
    });
    raw.push(...res.puzzles);
    perTier[plan.tier] = {written: res.puzzles.length, shortfall: res.shortfall};
  }

  const words = [...new Set(raw.flatMap((p) => p.answers))];
  const defs = await resolveDefinitions(words, deps.cache, deps.fetchFn, deps.concurrency);
  saveDefinitionCache(deps.cachePath, deps.cache);

  const puzzles = raw.map((p) => attachDefinitions(p, defs, deps.genVersion));
  await writePuzzles(puzzles);
  await updateLibraryMeta(await getStats());

  return {written: puzzles.length, perTier};
}

export function defaultDeps(): GenerateDeps {
  const wordData = loadWordDataFromFiles(
    VALIDITY_FILE,
    FREQUENCY_FILE,
    COMMON_FREQUENCY_CUTOFF,
  );
  // Seed the rng from the wall clock so successive runs explore new anchors.
  const seed = Date.now() & 0xffffffff;
  return {
    wordData,
    index: buildAnagramIndex(wordData.commonWords),
    fetchFn: dictionaryApiFetch(DEFINITION_MAX_RETRIES),
    cache: loadDefinitionCache(DEFINITIONS_CACHE_FILE),
    cachePath: DEFINITIONS_CACHE_FILE,
    concurrency: DEFINITION_CONCURRENCY,
    genVersion: GEN_VERSION,
    rng: mulberry32(seed),
  };
}
