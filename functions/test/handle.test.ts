import {describe, test, expect} from "@jest/globals";
import * as admin from "firebase-admin";
import {ensureHandle, slugifyHandle, uidForHandle} from "../src/services/handle_service";
import {getOrCreateProfile} from "../src/services/profile_service";

describe("handle_service", () => {
  test("slugifyHandle keeps letters+digits, lowercases, falls back to player", () => {
    expect(slugifyHandle("Grace Hopper")).toBe("gracehopper");
    expect(slugifyHandle("A.J. 99!")).toBe("aj99");
    expect(slugifyHandle("****")).toBe("player");
    expect(slugifyHandle("")).toBe("player");
  });

  test("ensureHandle reserves a unique index doc and writes it onto the user", async () => {
    const {handle, handleLower} = await ensureHandle("h-user-1", "Trinity");
    expect(handleLower).toBe(handle.toLowerCase());
    const idx = await admin.firestore().collection("usernames").doc(handleLower).get();
    expect(idx.data()?.uid).toBe("h-user-1");
    const user = await admin.firestore().collection("users").doc("h-user-1").get();
    expect(user.data()?.handle).toBe(handle);
    expect(await uidForHandle(handle.toUpperCase())).toBe("h-user-1"); // case-insensitive
  });

  test("a second user with the same base name gets a distinct handle", async () => {
    const a = await ensureHandle("h-user-2a", "Morpheus");
    const b = await ensureHandle("h-user-2b", "Morpheus");
    expect(a.handleLower).not.toBe(b.handleLower);
    expect(b.handleLower.startsWith("morpheus")).toBe(true);
  });

  test("ensureHandle is idempotent for the same user", async () => {
    const first = await ensureHandle("h-user-3", "Neo");
    const again = await ensureHandle("h-user-3", "Neo");
    expect(again.handleLower).toBe(first.handleLower);
  });

  test("getOrCreateProfile provisions a handle and the new fields", async () => {
    const p = await getOrCreateProfile("h-user-4");
    expect(p.handle.length).toBeGreaterThanOrEqual(3);
    expect(p.public).toBe(false);
    expect(p.isGuest).toBe(false);
  });
});
