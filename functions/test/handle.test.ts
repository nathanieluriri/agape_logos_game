import {describe, test, expect} from "@jest/globals";
import * as admin from "firebase-admin";
import {ensureHandle, isValidHandle, setHandle, slugifyHandle, uidForHandle} from "../src/services/handle_service";
import {getOrCreateProfile} from "../src/services/profile_service";
import {respondFriendRequest, sendFriendRequest} from "../src/services/social_service";

describe("isValidHandle", () => {
  test("accepts 3-20 alphanumerics and underscore", () => {
    expect(isValidHandle("nat_word")).toBe(true);
    expect(isValidHandle("abc")).toBe(true);
  });

  test("rejects too short, too long, and bad characters", () => {
    expect(isValidHandle("ab")).toBe(false);
    expect(isValidHandle("a".repeat(21))).toBe(false);
    expect(isValidHandle("has space")).toBe(false);
    expect(isValidHandle("bad-dash")).toBe(false);
  });
});

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

  test("setHandle claims a new handle and releases the previous one", async () => {
    const {handle: original} = await ensureHandle("h-user-5", "Cypher");
    const out = await setHandle("h-user-5", "cypher_new_handle");
    expect(out).toEqual({ok: true, handle: "cypher_new_handle"});
    expect(await uidForHandle("cypher_new_handle")).toBe("h-user-5");
    expect(await uidForHandle(original)).toBeNull();
  });

  test("setHandle rejects an invalid handle", async () => {
    const out = await setHandle("h-user-6", "no spaces");
    expect(out).toEqual({ok: false, reason: "invalid"});
  });

  test("setHandle rejects a handle already held by someone else", async () => {
    await ensureHandle("h-user-7a", "Trinity2");
    const {handle: taken} = await ensureHandle("h-user-7b", "Trinity2Rival");
    const out = await setHandle("h-user-7a", taken);
    expect(out).toEqual({ok: false, reason: "taken"});
  });

  test("re-claiming your own current handle is a no-op success", async () => {
    const {handle} = await ensureHandle("h-user-8", "Neo2");
    const out = await setHandle("h-user-8", handle);
    expect(out).toEqual({ok: true, handle});
  });

  test("setHandle pushes the new handle onto every friend's edge doc", async () => {
    // A and B are friends; the friend edges embed A's handle at write time. When A
    // renames, B's list must not keep showing the released old handle (a stranger
    // could claim it, so copying it from the list would add the wrong person).
    const {handle: oldHandle} = await ensureHandle("h-user-9a", "Switch");
    await ensureHandle("h-user-9b", "Apoc");
    await sendFriendRequest("h-user-9a", {toUid: "h-user-9b"});
    await respondFriendRequest("h-user-9b", "h-user-9a", true); // accept: writes both edges

    const before = await admin.firestore()
      .doc("users/h-user-9b/friends/h-user-9a").get();
    expect(before.data()?.handle).toBe(oldHandle);

    const out = await setHandle("h-user-9a", "switch_reloaded");
    expect(out).toEqual({ok: true, handle: "switch_reloaded"});

    const after = await admin.firestore()
      .doc("users/h-user-9b/friends/h-user-9a").get();
    expect(after.data()?.handle).toBe("switch_reloaded");
    // The rest of the edge doc survives the merge.
    expect(after.data()?.uid).toBe("h-user-9a");
    expect(after.data()?.displayName).toBeDefined();
  });
});
