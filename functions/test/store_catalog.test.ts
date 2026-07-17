import {describe, test, expect} from "@jest/globals";
import {
  STORE_ITEMS,
  STORE_ITEM_IDS,
  getStoreItem,
  grantsFor,
} from "../src/store/catalog";

describe("store catalog", () => {
  test("item ids are unique and enumerated", () => {
    const ids = STORE_ITEMS.map((i) => i.id);
    expect(new Set(ids).size).toBe(ids.length);
    expect([...STORE_ITEM_IDS].sort()).toEqual([...ids].sort());
  });

  test("every item has a positive cost and purchase cap", () => {
    for (const i of STORE_ITEMS) {
      expect(i.cost).toBeGreaterThan(0);
      expect(i.maxPerPurchase).toBeGreaterThan(0);
    }
  });

  test("powerups carry forward-looking effect metadata", () => {
    const freeze = getStoreItem("freeze_letter")!;
    expect(freeze.effect).toMatchObject({target: "opponent", durationSec: 10});
  });

  test("bundles grant existing base items and undercut buying singly", () => {
    const pack = getStoreItem("hint_pack")!;
    expect(pack.grants).toEqual({hint: 5});
    expect(pack.cost).toBeLessThan(getStoreItem("hint")!.cost * 5);
    for (const id of Object.keys(pack.grants!)) {
      expect(getStoreItem(id)).toBeDefined();
    }
    const skirmish = getStoreItem("skirmish_pack")!;
    const singly = Object.entries(skirmish.grants!).reduce(
      (sum, [id, n]) => sum + getStoreItem(id)!.cost * n,
      0,
    );
    expect(skirmish.cost).toBeLessThan(singly);
  });

  test("grantsFor multiplies base grants by quantity", () => {
    expect(grantsFor(getStoreItem("hint")!, 3)).toEqual({hint: 3});
    expect(grantsFor(getStoreItem("skirmish_pack")!, 2)).toEqual({
      freeze_letter: 4,
      fog: 4,
      shield: 2,
    });
  });
});
