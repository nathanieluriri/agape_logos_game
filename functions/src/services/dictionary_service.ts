import {db} from "../firebase";
import {DICTIONARY_MAX} from "../schemas/dictionary";
import {PuzzleDoc, fetchPuzzles} from "./assignment_service";

export interface DictionaryEntry {
  word: string;
  definition: string | null;
  tier: string;
  puzzleId: string;
}

// Pure: flatten every answer across [puzzles] into dictionary entries,
// de-duplicated by UPPERCASE word (first occurrence wins, so the earliest
// completed puzzle owns a word shared across tiers), capped at [limit], and
// sorted alphabetically. Exported for a fast unit test without the emulator.
export function flattenDictionary(
  puzzles: PuzzleDoc[],
  limit: number,
): DictionaryEntry[] {
  const seen = new Set<string>();
  const entries: DictionaryEntry[] = [];
  for (const p of puzzles) {
    for (const a of p.answers) {
      const key = a.word.toUpperCase();
      if (seen.has(key)) continue;
      seen.add(key);
      entries.push({
        word: a.word,
        definition: a.definition,
        tier: p.tier,
        puzzleId: p.letterKey,
      });
      if (entries.length >= limit) break;
    }
    if (entries.length >= limit) break;
  }
  entries.sort((x, y) => x.word.localeCompare(y.word));
  return entries;
}

// The caller's solved words across every completed puzzle. Reads the user's
// completed assignments (ids only), resolves those ids against the global
// `puzzles` collection (fetchPuzzles uses getAll and skips missing docs), and
// flattens their PLAINTEXT answers. Plaintext is correct here: these are the
// user's own solved puzzles (their history), so no per-user encryption applies.
//
// PLAN (semantics): today an assignment is flipped completed=true only by
// savePuzzleResult, which the client calls exclusively on a full solve
// (game_controller.commitWin fires only when every answer is found). So
// "completed" == "all words found" == "won" in the current codebase, and
// including all completed puzzles is exactly the solved-word history. If a
// future flow ever marks an assignment completed WITHOUT a full solve (a skip /
// consume path), gate this on a won marker instead (e.g. only puzzles whose
// puzzleResults doc has score > 0). Orchestrator: confirm no such path exists
// before shipping; there is none today.
export async function getDictionary(
  uid: string,
  limit: number = DICTIONARY_MAX,
): Promise<{entries: DictionaryEntry[]}> {
  const snap = await db
    .collection("users").doc(uid).collection("assignments")
    .where("completed", "==", true)
    .select() // ids only; we resolve full docs from the pool below
    .get();
  const puzzleIds = snap.docs.map((d) => d.id);
  const puzzles = await fetchPuzzles(puzzleIds);
  return {entries: flattenDictionary(puzzles, limit)};
}
