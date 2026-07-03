import {describe, test, expect} from "@jest/globals";
import {getCoins, getOrCreateProfile, updateProfile} from "../src/services/profile_service";

describe("profile_service", () => {
  test("getOrCreateProfile creates defaults then is idempotent", async () => {
    const uid = "svc-user-1";
    const first = await getOrCreateProfile(uid);
    expect(first.uid).toBe(uid);
    expect(first.displayName).toBe("Player");
    expect(first.avatarId).toBe("avatar_01");
    expect(first.highestLevel).toBe(0);
    expect(first.totalScore).toBe(0);
    expect(first.coins).toBe(0);
    expect(first.inventory).toEqual({});
    expect(first.createdAt).toBeGreaterThan(0);

    const second = await getOrCreateProfile(uid);
    expect(second.createdAt).toBe(first.createdAt);
  });

  test("updateProfile merges editable fields and bumps updatedAt", async () => {
    const uid = "svc-user-2";
    const before = await getOrCreateProfile(uid);
    const after = await updateProfile(uid, {displayName: "Trinity", soundEnabled: false});
    expect(after.displayName).toBe("Trinity");
    expect(after.soundEnabled).toBe(false);
    expect(after.updatedAt).toBeGreaterThanOrEqual(before.updatedAt);
  });

  test("getCoins provisions the profile and returns the balance", async () => {
    const {coins} = await getCoins("svc-user-coins");
    expect(coins).toBe(0);
  });
});
