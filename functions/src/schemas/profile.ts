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
  coins: z.number().int(),
  // Owned consumables (base store item id -> quantity). Empty for a new user.
  inventory: z.record(z.number().int()),
  // Social layer (plan 13). handle is the searchable @handle; public gates
  // whether the profile is findable/viewable by non-friends; isGuest is set
  // from the anonymous sign-in provider at provision time.
  handle: z.string(),
  public: z.boolean(),
  isGuest: z.boolean(),
  createdAt: z.number().int(),
  updatedAt: z.number().int(),
});

// Lightweight coin-only response for GET /me/coins, when the client just needs
// the wallet balance without the full profile payload.
export const CoinsResponseSchema = z.object({
  coins: z.number().int(),
});

// Per-user answer-decryption key (base64), for GET /me/answer-key.
export const AnswerKeyResponseSchema = z.object({
  key: z.string(),
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
  coins: 0,
  inventory: {} as Record<string, number>,
  // PLAN: handle/handleLower/displayNameLower are NOT static defaults; they are
  // set during provisioning by ensureHandle and the displayNameLower write.
  public: false,
  isGuest: false,
} as const;
