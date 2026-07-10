import {z} from "zod";

// A hard cap on the number of words returned in one dictionary response. A user
// who has completed hundreds of puzzles could otherwise return thousands of
// words in a single payload. This bounds it; see the PLAN note in the service
// about pagination if this ceiling is ever reached in practice.
export const DICTIONARY_MAX = 2000;

// One solved word: the word, its definition (may be null in the pool), the tier
// of the puzzle it came from, and that puzzle's id (letter key) for reference.
export const DictionaryEntrySchema = z.object({
  word: z.string(),
  definition: z.string().nullable(),
  tier: z.string(),
  puzzleId: z.string(),
});
export type DictionaryEntryResponse = z.infer<typeof DictionaryEntrySchema>;

// GET /me/dictionary response: the flattened, de-duplicated word list.
export const DictionaryResponseSchema = z.object({
  entries: z.array(DictionaryEntrySchema),
});
