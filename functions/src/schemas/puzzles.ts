import {z} from "zod";

const TIER_KEYS = ["easy", "medium", "hard", "expert"] as const;
const tierCount = z.number().int().nonnegative().optional();

export const DrawBodySchema = z
  .object({
    easy: tierCount,
    medium: tierCount,
    hard: tierCount,
    expert: tierCount,
  })
  .refine(
    (b) => TIER_KEYS.some((k) => (b[k] ?? 0) > 0),
    "at least one tier count must be greater than 0",
  );
export type DrawBody = z.infer<typeof DrawBodySchema>;

// Same idempotency-key rules as the level-result sample: present, non-empty,
// no slash (would split the Firestore doc path), within 1500 bytes.
export const DrawHeadersSchema = z.object({
  "idempotency-key": z
    .string()
    .min(1)
    .refine((k) => k.trim() !== "" && !k.includes("/"), "invalid idempotency-key")
    .refine((k) => Buffer.byteLength(k, "utf8") <= 1500, "idempotency-key too long"),
});

export const AssignedQuerySchema = z.object({
  status: z.enum(["incomplete", "completed", "all"]).default("incomplete"),
});

export const PuzzleResultParamsSchema = z.object({
  puzzleId: z.string().regex(/^[A-Z]+$/, "puzzleId must be uppercase letters"),
});

export const PuzzleResultHeadersSchema = DrawHeadersSchema;

export const PuzzleResultBodySchema = z.object({
  score: z.number().int(),
  completedAt: z.number().int(),
  // Optional progression level this result completed. When present the server
  // bumps the profile's highestLevel to max(current, level). Puzzles are
  // identified by letter key, not a level number, so this is the only channel
  // the client has to advance highestLevel.
  level: z.number().int().nonnegative().optional(),
});
export type PuzzleResultBody = z.infer<typeof PuzzleResultBodySchema>;
