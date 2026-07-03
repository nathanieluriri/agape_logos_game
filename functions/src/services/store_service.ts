import {FieldValue} from "firebase-admin/firestore";
import {db} from "../firebase";
import {getStoreItem, grantsFor} from "../store/catalog";
import {getOrCreateProfile} from "./profile_service";

export type PurchaseResult =
  | {
      ok: true;
      replay: boolean;
      charged: number;
      coins: number;
      inventory: Record<string, number>;
    }
  | {ok: false; reason: "unknown_item"}
  | {ok: false; reason: "insufficient_coins"; cost: number; coins: number};

// Buys [quantity] of [itemId] for [uid], charging coins and granting the item's
// base consumables. Idempotent on [idempotencyKey]: a replay never double-charges
// (a purchases/{key} ledger doc marks it done). A successful purchase implies the
// profile already exists (coins were earned by playing), so no provisioning is
// needed here; a 0-coin new user simply hits `insufficient_coins`.
export async function purchase(
  uid: string,
  idempotencyKey: string,
  itemId: string,
  quantity: number,
): Promise<PurchaseResult> {
  const item = getStoreItem(itemId);
  if (!item) return {ok: false, reason: "unknown_item"};

  const q = Math.max(1, Math.min(quantity, item.maxPerPurchase));
  const cost = item.cost * q;
  const grants = grantsFor(item, q);

  const userRef = db.collection("users").doc(uid);
  const ledgerRef = userRef.collection("purchases").doc(idempotencyKey);

  return db.runTransaction<PurchaseResult>(async (tx) => {
    const ledgerSnap = await tx.get(ledgerRef);
    const snap = await tx.get(userRef);
    const data = (snap.data() ?? {}) as Record<string, unknown>;
    const coins = (data.coins as number) ?? 0;
    const inventory = (data.inventory as Record<string, number>) ?? {};

    if (ledgerSnap.exists) {
      // Already applied on an earlier delivery: return current state, no charge.
      return {
        ok: true,
        replay: true,
        charged: (ledgerSnap.data()?.cost as number) ?? cost,
        coins,
        inventory,
      };
    }

    if (coins < cost) {
      return {ok: false, reason: "insufficient_coins", cost, coins};
    }

    // Nested per-item increments: users/{uid}.inventory.<baseId> += n.
    const invUpdate: Record<string, unknown> = {};
    for (const [id, n] of Object.entries(grants)) {
      invUpdate[id] = FieldValue.increment(n);
    }

    tx.set(ledgerRef, {
      itemId,
      quantity: q,
      cost,
      grants,
      at: FieldValue.serverTimestamp(),
    });
    tx.set(
      userRef,
      {
        coins: FieldValue.increment(-cost),
        inventory: invUpdate,
        updatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true},
    );

    // Post-state without a re-read.
    const newInventory: Record<string, number> = {...inventory};
    for (const [id, n] of Object.entries(grants)) {
      newInventory[id] = (newInventory[id] ?? 0) + n;
    }
    return {
      ok: true,
      replay: false,
      charged: cost,
      coins: coins - cost,
      inventory: newInventory,
    };
  });
}

// The caller's owned consumables (provisions the profile on first read).
export async function getInventory(uid: string): Promise<Record<string, number>> {
  const profile = await getOrCreateProfile(uid);
  return profile.inventory;
}
