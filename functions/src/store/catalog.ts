// The store catalog: what coins can buy. Purely data + pure helpers; the
// purchase transaction lives in services/store_service.
//
// Design notes
// ------------
// - Everything the player owns is tracked as BASE CONSUMABLES in their
//   inventory (one counter per base item id). Bundles don't create their own
//   inventory line; they GRANT base items (usually at a discount), so the
//   multiplayer client only ever has to understand base items.
// - Powerups are inert for now (no gameplay hook). The `effect` metadata is
//   forward-looking so the eventual real-time multiplayer mode can read
//   duration/target/magnitude without another migration.
// - Costs are tuned against the current economy (a solved puzzle pays
//   10 + score coins): a hint is a small sink, offensive powerups cost more the
//   more they swing a match, and bundles undercut buying singly.

export type StoreCategory = "hint" | "powerup";
export type PowerupKind = "hint" | "offense" | "defense" | "utility";

// Who a powerup acts on when it eventually goes live in multiplayer.
export type EffectTarget = "self" | "opponent";

export interface PowerupEffect {
  target: EffectTarget;
  // Seconds the effect lasts, when time-based (0 for instantaneous effects).
  durationSec: number;
  // Free-form magnitude the multiplayer engine will interpret (e.g. points
  // multiplier, number of letters, percent). Optional.
  magnitude?: number;
  // One-line rules text for the eventual gameplay hook.
  rule: string;
}

export interface StoreItem {
  id: string;
  name: string;
  description: string;
  category: StoreCategory;
  kind: PowerupKind;
  // Coins charged per unit purchased.
  cost: number;
  // Safety cap on quantity per single purchase call.
  maxPerPurchase: number;
  // Effect metadata (absent for the plain hint and for bundles).
  effect?: PowerupEffect;
  // If set, buying this grants these BASE item quantities instead of itself
  // (bundles). Absent means the item grants one of itself.
  grants?: Record<string, number>;
}

// Base consumables (each grants itself).
const BASE_ITEMS: StoreItem[] = [
  {
    id: "hint",
    name: "Hint",
    description: "Reveal the next letter of an unsolved word.",
    category: "hint",
    kind: "hint",
    cost: 50,
    maxPerPurchase: 20,
  },
  {
    id: "freeze_letter",
    name: "Letter Freeze",
    description: "Lock one of your opponent's rack letters so they can't use it for 10 seconds.",
    category: "powerup",
    kind: "offense",
    cost: 120,
    maxPerPurchase: 10,
    effect: {target: "opponent", durationSec: 10, magnitude: 1, rule: "Disable 1 opponent letter for 10s."},
  },
  {
    id: "fog",
    name: "Fog Bank",
    description: "Blur your opponent's board for 8 seconds.",
    category: "powerup",
    kind: "offense",
    cost: 100,
    maxPerPurchase: 10,
    effect: {target: "opponent", durationSec: 8, rule: "Obscure the opponent's board for 8s."},
  },
  {
    id: "scramble",
    name: "Scramble",
    description: "Shuffle your opponent's rack once, breaking their setup.",
    category: "powerup",
    kind: "offense",
    cost: 90,
    maxPerPurchase: 10,
    effect: {target: "opponent", durationSec: 0, rule: "Force-shuffle the opponent's rack."},
  },
  {
    id: "word_steal",
    name: "Word Steal",
    description: "Steal one word your opponent has found, taking its points.",
    category: "powerup",
    kind: "offense",
    cost: 260,
    maxPerPurchase: 5,
    effect: {target: "opponent", durationSec: 0, magnitude: 1, rule: "Take 1 found word + its points from the opponent."},
  },
  {
    id: "shield",
    name: "Bubble Shield",
    description: "Nullify the next powerup used against you.",
    category: "powerup",
    kind: "defense",
    cost: 150,
    maxPerPurchase: 10,
    effect: {target: "self", durationSec: 0, rule: "Block the next incoming powerup."},
  },
  {
    id: "combo_lock",
    name: "Combo Lock",
    description: "Your combo won't reset on your next wrong word.",
    category: "powerup",
    kind: "defense",
    cost: 110,
    maxPerPurchase: 10,
    effect: {target: "self", durationSec: 0, rule: "Protect your combo from one miss."},
  },
  {
    id: "time_boost",
    name: "Time Boost",
    description: "Add 15 seconds to your own clock.",
    category: "powerup",
    kind: "utility",
    cost: 80,
    maxPerPurchase: 20,
    effect: {target: "self", durationSec: 15, rule: "+15s to your round timer."},
  },
  {
    id: "double_points",
    name: "Double Points",
    description: "Your next valid word scores double.",
    category: "powerup",
    kind: "utility",
    cost: 140,
    maxPerPurchase: 10,
    effect: {target: "self", durationSec: 0, magnitude: 2, rule: "2x points on your next valid word."},
  },
];

// Bundles grant base items at a discount vs. buying singly.
const BUNDLE_ITEMS: StoreItem[] = [
  {
    id: "hint_pack",
    name: "Hint Pack",
    description: "Five hints at a discount.",
    category: "hint",
    kind: "hint",
    cost: 200, // vs 5 x 50 = 250
    maxPerPurchase: 5,
    grants: {hint: 5},
  },
  {
    id: "skirmish_pack",
    name: "Skirmish Pack",
    description: "A starter kit of offense and defense: 2 Letter Freeze, 2 Fog Bank, 1 Bubble Shield.",
    category: "powerup",
    kind: "offense",
    cost: 500, // vs 2*120 + 2*100 + 150 = 590
    maxPerPurchase: 5,
    grants: {freeze_letter: 2, fog: 2, shield: 1},
  },
];

export const STORE_ITEMS: StoreItem[] = [...BASE_ITEMS, ...BUNDLE_ITEMS];

const BY_ID: Record<string, StoreItem> = Object.fromEntries(
  STORE_ITEMS.map((i) => [i.id, i]),
);

export const STORE_ITEM_IDS = STORE_ITEMS.map((i) => i.id) as [string, ...string[]];

export function getStoreItem(id: string): StoreItem | undefined {
  return BY_ID[id];
}

// The base-item quantities granted by purchasing [quantity] of [item].
export function grantsFor(item: StoreItem, quantity: number): Record<string, number> {
  const per = item.grants ?? {[item.id]: 1};
  const out: Record<string, number> = {};
  for (const [id, n] of Object.entries(per)) out[id] = n * quantity;
  return out;
}
