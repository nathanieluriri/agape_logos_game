import {z} from "zod";

// A settable @handle shape (auto-derived in this plan; validated for the
// friend-by-handle path). Letters, digits, underscore; 3-20 chars.
export const HandleSchema = z
  .string()
  .min(3)
  .max(20)
  .regex(/^[A-Za-z0-9_]+$/, "handle may only contain letters, digits, and underscore");

// Same idempotency-key rules as the store writes.
export const IdempotencyHeaderSchema = z.object({
  "idempotency-key": z
    .string()
    .min(1)
    .refine((k) => k.trim() !== "" && !k.includes("/"), "invalid idempotency-key")
    .refine((k) => Buffer.byteLength(k, "utf8") <= 1500, "idempotency-key too long"),
});

// PUT /me/privacy body.
export const PrivacyBodySchema = z.object({public: z.boolean()}).strict();
export type PrivacyBody = z.infer<typeof PrivacyBodySchema>;

// GET /users/search query.
export const UserSearchQuerySchema = z.object({
  q: z.string().min(1).max(30),
  limit: z.coerce.number().int().min(1).max(25).optional(),
});

// POST /friends/request body: exactly one of toUid | handle.
export const FriendRequestBodySchema = z
  .object({
    toUid: z.string().min(1).optional(),
    handle: HandleSchema.optional(),
  })
  .refine((b) => Boolean(b.toUid) !== Boolean(b.handle), "provide exactly one of toUid or handle");
export type FriendRequestBody = z.infer<typeof FriendRequestBodySchema>;

// POST /friends/respond body.
export const FriendRespondBodySchema = z
  .object({fromUid: z.string().min(1), accept: z.boolean()})
  .strict();
export type FriendRespondBody = z.infer<typeof FriendRespondBodySchema>;

// GET /me/matches query.
export const MatchHistoryQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(50).optional(),
});

// --- Response shapes (for OpenAPI) ---

// Minimal public projection returned by search + carried on friend/request docs.
// Stats are optional: search omits them; the single-user detail endpoint fills
// them in. Never carries private fields (coins, inventory, timestamps).
export const PublicProfileSchema = z.object({
  uid: z.string(),
  handle: z.string(),
  displayName: z.string(),
  avatarId: z.string(),
  isGuest: z.boolean(),
  highestLevel: z.number().int().optional(),
  totalScore: z.number().int().optional(),
});

export const UserSearchResponseSchema = z.object({
  users: z.array(PublicProfileSchema),
});

export const FriendSchema = z.object({
  uid: z.string(),
  handle: z.string(),
  displayName: z.string(),
  avatarId: z.string(),
  since: z.number().int(),
});

export const FriendRequestSchema = z.object({
  fromUid: z.string(),
  handle: z.string(),
  displayName: z.string(),
  avatarId: z.string(),
  at: z.number().int(),
});

export const FriendsResponseSchema = z.object({
  friends: z.array(FriendSchema),
  requests: z.array(FriendRequestSchema),
});

export const MatchHistoryEntrySchema = z.object({
  matchId: z.string(),
  opponentUid: z.string(),
  opponentName: z.string(),
  result: z.enum(["win", "loss", "draw"]),
  score: z.number().int(),
  opponentScore: z.number().int(),
  endedAt: z.number().int(),
});

export const MatchHistoryResponseSchema = z.object({
  history: z.array(MatchHistoryEntrySchema),
});

export const PublicProfileDetailResponseSchema = z.object({
  profile: PublicProfileSchema,
  recentMatches: z.array(MatchHistoryEntrySchema),
});

export const OkResponseSchema = z.object({ok: z.boolean()});
