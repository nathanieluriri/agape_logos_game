import {z} from "zod";

// Built-in avatar keys (no uploads). Expand this list as art is added.
export const AVATAR_IDS = [
  "avatar_01",
  "avatar_02",
  "avatar_03",
  "avatar_04",
  "avatar_05",
  "avatar_06",
] as const;

// Editable profile fields. Strict so unknown or server-managed keys
// (highestLevel, totalScore, timestamps) are rejected with 400.
export const ProfileUpdateSchema = z
  .object({
    displayName: z.string().min(1).max(30).optional(),
    avatarId: z.enum(AVATAR_IDS).optional(),
    locale: z.string().min(2).max(10).optional(),
    soundEnabled: z.boolean().optional(),
    musicEnabled: z.boolean().optional(),
  })
  .strict();

export type ProfilePatch = z.infer<typeof ProfileUpdateSchema>;

// The full profile as returned to clients (timestamps are epoch millis).
export const ProfileResponseSchema = z.object({
  uid: z.string(),
  displayName: z.string(),
  avatarId: z.string(),
  locale: z.string(),
  soundEnabled: z.boolean(),
  musicEnabled: z.boolean(),
  highestLevel: z.number().int(),
  totalScore: z.number().int(),
  createdAt: z.number().int(),
  updatedAt: z.number().int(),
});

// Field defaults written on first auto-create (uid and timestamps added by
// the service).
export const DEFAULT_PROFILE = {
  displayName: "Player",
  avatarId: "avatar_01",
  locale: "en",
  soundEnabled: true,
  musicEnabled: true,
  highestLevel: 0,
  totalScore: 0,
} as const;
