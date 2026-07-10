import {z} from "zod";
import {kMatchCodeAlphabet, kMatchCodeLength} from "../services/match_codes";

// Only the three player-facing difficulties are offered in match settings (the
// pool's "expert" tier is reserved). difficulty selects the rack tier; see the
// rackSize note below.
export const MatchDifficultySchema = z.enum(["easy", "medium", "hard"]);
export type MatchDifficulty = z.infer<typeof MatchDifficultySchema>;

export const PowerupKindSchema = z.enum([
  "letter_freeze",
  "fog_bank",
  "scramble",
  "word_steal",
]);
export type PowerupKind = z.infer<typeof PowerupKindSchema>;

// Match settings (plan 10 section 8.2). Only the creator sets these.
// PLAN: rackSize default 7 matches the frozen contract, but the existing pool
// tops out at rackSize 6. The rack is drawn by difficulty->tier and the drawn
// racks/{uid}.rackSize is authoritative; the client renders from rack.letters,
// not settings.rackSize. Expanding the pool to size 7 (or lowering the default)
// is a later product call and does not block multiplayer.
export const MatchSettingsSchema = z.object({
  difficulty: MatchDifficultySchema.default("medium"),
  durationSec: z.number().int().min(30).max(600).default(120),
  rackSize: z.number().int().min(3).max(9).default(7),
  theme: z.string().min(1).max(64).nullable().default(null),
});
export type MatchSettings = z.infer<typeof MatchSettingsSchema>;

// Reuse the exact idempotency-key rules the other optimistic writes use.
export const IdempotencyHeadersSchema = z.object({
  "idempotency-key": z
    .string()
    .min(1)
    .refine((k) => k.trim() !== "" && !k.includes("/"), "invalid idempotency-key")
    .refine((k) => Buffer.byteLength(k, "utf8") <= 1500, "idempotency-key too long"),
});

export const MatchParamsSchema = z.object({
  id: z.string().min(1).max(64),
});

export const CreateMatchBodySchema = z.object({
  settings: MatchSettingsSchema.optional(),
});

const codeRegex = new RegExp(`^[${kMatchCodeAlphabet}]{${kMatchCodeLength}}$`);
export const JoinMatchBodySchema = z.object({
  code: z
    .string()
    .transform((s) => s.trim().toUpperCase())
    .refine((s) => codeRegex.test(s), "invalid code"),
});

export const ReadyBodySchema = z.object({ready: z.boolean().default(true)});

export const StartBodySchema = z.object({}).strict();

export const SubmitBodySchema = z.object({
  word: z
    .string()
    .transform((s) => s.trim().toUpperCase())
    .refine((s) => /^[A-Z]{2,15}$/.test(s), "word must be 2-15 letters"),
});

export const PowerupBodySchema = z.object({kind: PowerupKindSchema});

// --- Response shapes (for OpenAPI) ---
export const CreateMatchResponseSchema = z.object({matchId: z.string(), code: z.string()});
export const JoinMatchResponseSchema = z.object({matchId: z.string()});
export const OkResponseSchema = z.object({
  ok: z.boolean(),
  status: z.string().optional(),
  reason: z.string().optional(),
});
export const SubmitResponseSchema = z.object({
  accepted: z.boolean(),
  score: z.number().int(),
  wordsFound: z.number().int(),
  reason: z.string().optional(),
});
export const ThemesResponseSchema = z.object({
  themes: z.array(z.object({id: z.string(), name: z.string()})),
});
