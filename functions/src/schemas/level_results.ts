import {z} from "zod";

export const LevelParamsSchema = z.object({
  levelId: z.coerce.number().int(),
});

// Mirrors the existing hand-rolled checks: present, non-empty, no slash
// (slashes would split the Firestore document path), and within 1500 bytes.
export const LevelResultHeadersSchema = z.object({
  "idempotency-key": z
    .string()
    .min(1)
    .refine((k) => k.trim() !== "" && !k.includes("/"), "invalid idempotency-key")
    .refine((k) => Buffer.byteLength(k, "utf8") <= 1500, "idempotency-key too long"),
});

// Non-strict: extra client fields (id, levelId, synced) are ignored, matching
// the current route which only reads score and completedAt.
export const LevelResultBodySchema = z.object({
  score: z.number().int(),
  completedAt: z.number().int(),
});

export type LevelResultBody = z.infer<typeof LevelResultBodySchema>;
