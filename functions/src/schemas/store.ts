import {z} from "zod";
import {STORE_ITEM_IDS} from "../store/catalog";

// Purchase input: a known item id and an optional quantity (server also clamps
// to the item's maxPerPurchase).
export const PurchaseBodySchema = z.object({
  itemId: z.enum(STORE_ITEM_IDS),
  quantity: z.number().int().min(1).max(99).default(1),
});
export type PurchaseBody = z.infer<typeof PurchaseBodySchema>;

// Same idempotency-key rules as the other optimistic writes.
export const PurchaseHeadersSchema = z.object({
  "idempotency-key": z
    .string()
    .min(1)
    .refine((k) => k.trim() !== "" && !k.includes("/"), "invalid idempotency-key")
    .refine((k) => Buffer.byteLength(k, "utf8") <= 1500, "idempotency-key too long"),
});

// --- Response shapes (for OpenAPI) ---

const PowerupEffectSchema = z.object({
  target: z.enum(["self", "opponent"]),
  durationSec: z.number().int(),
  magnitude: z.number().optional(),
  rule: z.string(),
});

export const StoreItemSchema = z.object({
  id: z.string(),
  name: z.string(),
  description: z.string(),
  category: z.enum(["hint", "powerup"]),
  kind: z.enum(["hint", "offense", "defense", "utility"]),
  cost: z.number().int(),
  maxPerPurchase: z.number().int(),
  effect: PowerupEffectSchema.optional(),
  grants: z.record(z.number().int()).optional(),
});

export const StoreCatalogResponseSchema = z.object({
  items: z.array(StoreItemSchema),
});

export const InventoryResponseSchema = z.object({
  inventory: z.record(z.number().int()),
});

export const PurchaseResponseSchema = z.object({
  coins: z.number().int(),
  inventory: z.record(z.number().int()),
  charged: z.number().int(),
  replay: z.boolean(),
});
