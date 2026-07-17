import {FieldValue, Timestamp} from "firebase-admin/firestore";
import {db} from "../firebase";
import {getOrCreateProfile} from "./profile_service";
import {uidForHandle} from "./handle_service";

export const SEARCH_CAP = 25;

export interface PublicProfileView {
  uid: string;
  handle: string;
  displayName: string;
  avatarId: string;
  isGuest: boolean;
  highestLevel?: number;
  totalScore?: number;
}

export interface MatchHistoryView {
  matchId: string;
  opponentUid: string;
  opponentName: string;
  result: string;
  score: number;
  opponentScore: number;
  endedAt: number;
}

export function millis(value: unknown): number {
  if (value instanceof Timestamp) return value.toMillis();
  return typeof value === "number" ? value : 0;
}

// Minimal, non-sensitive projection of a user doc (never coins / inventory).
export function corePublic(uid: string, data: Record<string, unknown>): PublicProfileView {
  return {
    uid,
    handle: (data.handle as string) ?? "",
    displayName: (data.displayName as string) ?? "Player",
    avatarId: (data.avatarId as string) ?? "avatar_01",
    isGuest: (data.isGuest as boolean) ?? false,
  };
}

export function toHistory(data: Record<string, unknown>): MatchHistoryView {
  return {
    matchId: (data.matchId as string) ?? "",
    opponentUid: (data.opponentUid as string) ?? "",
    opponentName: (data.opponentName as string) ?? "",
    result: (data.result as string) ?? "draw",
    score: (data.score as number) ?? 0,
    opponentScore: (data.opponentScore as number) ?? 0,
    endedAt: millis(data.endedAt),
  };
}

// PUT /me/privacy: flip the public flag. Ensures the profile (and its handle)
// exist first so a brand-new user can go public in one call. Naturally
// idempotent (a boolean set), so no ledger doc is needed.
export async function setPrivacy(uid: string, isPublic: boolean): Promise<void> {
  await getOrCreateProfile(uid);
  await db.collection("users").doc(uid).set(
    {public: isPublic, updatedAt: FieldValue.serverTimestamp()},
    {merge: true},
  );
}

// Are a and b friends? (Checks a's friends subcollection for b.)
export async function areFriends(a: string, b: string): Promise<boolean> {
  const snap = await db.collection("users").doc(a).collection("friends").doc(b).get();
  return snap.exists;
}

// Prefix search over PUBLIC profiles only, matching a handle prefix OR a display
// name prefix (both lowercased). Two bounded range queries, merged and de-duped,
// capped. Returns the minimal projection (no stats, no private fields). The
// upper bound uses the high private-use codepoint U+F8FF as the standard
// Firestore "startsWith" sentinel.
export async function searchUsers(q: string, limit = SEARCH_CAP): Promise<PublicProfileView[]> {
  const term = q.trim().toLowerCase();
  if (!term) return [];
  const cap = Math.min(Math.max(limit, 1), SEARCH_CAP);
  const end = term + "";
  const users = db.collection("users");
  const [byHandle, byName] = await Promise.all([
    users.where("public", "==", true).orderBy("handleLower")
      .startAt(term).endAt(end).limit(cap).get(),
    users.where("public", "==", true).orderBy("displayNameLower")
      .startAt(term).endAt(end).limit(cap).get(),
  ]);
  const seen = new Map<string, PublicProfileView>();
  for (const doc of [...byHandle.docs, ...byName.docs]) {
    if (seen.has(doc.id)) continue;
    seen.set(doc.id, corePublic(doc.id, doc.data() as Record<string, unknown>));
    if (seen.size >= cap) break;
  }
  return [...seen.values()];
}

// Public detail: visible when the target is public, is the caller, or is the
// caller's friend. Returns null when hidden or missing (route maps null -> 403,
// so private and non-existent are indistinguishable to callers). Includes a
// small slice of recent match history for the profile screen.
export async function getPublicProfile(
  callerUid: string,
  targetUid: string,
): Promise<{profile: PublicProfileView; recentMatches: MatchHistoryView[]} | null> {
  const ref = db.collection("users").doc(targetUid);
  const snap = await ref.get();
  if (!snap.exists) return null;
  const data = snap.data() as Record<string, unknown>;
  const isPublic = (data.public as boolean) ?? false;
  const visible =
    callerUid === targetUid || isPublic || (await areFriends(targetUid, callerUid));
  if (!visible) return null;
  const profile: PublicProfileView = {
    ...corePublic(targetUid, data),
    highestLevel: (data.highestLevel as number) ?? 0,
    totalScore: (data.totalScore as number) ?? 0,
  };
  const hist = await ref.collection("matchHistory").orderBy("endedAt", "desc").limit(5).get();
  const recentMatches = hist.docs.map((d) => toHistory(d.data() as Record<string, unknown>));
  return {profile, recentMatches};
}

export type FriendRequestResult = {ok: true} | {ok: false; reason: "self" | "not_found"};

// POST /friends/request: create users/{toUid}/friendRequests/{fromUid}. Target
// is a uid or a handle (resolved via the usernames index). Idempotent (the doc
// id is the sender's uid). Snapshots the sender's public identity onto the
// request so the recipient renders it without an extra read. If they are already
// friends, this is a friendly no-op.
export async function sendFriendRequest(
  fromUid: string,
  target: {toUid?: string; handle?: string},
): Promise<FriendRequestResult> {
  let toUid = target.toUid ?? null;
  if (!toUid && target.handle) toUid = await uidForHandle(target.handle);
  if (!toUid) return {ok: false, reason: "not_found"};
  if (toUid === fromUid) return {ok: false, reason: "self"};

  const [me] = await Promise.all([
    getOrCreateProfile(fromUid),
    getOrCreateProfile(toUid),
  ]);
  if (await areFriends(fromUid, toUid)) return {ok: true};

  await db.collection("users").doc(toUid).collection("friendRequests").doc(fromUid).set({
    fromUid,
    handle: me.handle,
    displayName: me.displayName,
    avatarId: me.avatarId,
    at: FieldValue.serverTimestamp(),
  });
  return {ok: true};
}

export type RespondResult = {ok: true} | {ok: false; reason: "no_request"};

// POST /friends/respond. Accept: write reciprocal friend docs (both directions)
// and delete the pending request, in one transaction. Decline: delete the
// request. Idempotent: if already friends, accept still returns ok.
export async function respondFriendRequest(
  meUid: string,
  fromUid: string,
  accept: boolean,
): Promise<RespondResult> {
  const meRef = db.collection("users").doc(meUid);
  const fromRef = db.collection("users").doc(fromUid);
  const reqRef = meRef.collection("friendRequests").doc(fromUid);

  if (!accept) {
    await reqRef.delete();
    return {ok: true};
  }

  const [meProfile, fromProfile] = await Promise.all([
    getOrCreateProfile(meUid),
    getOrCreateProfile(fromUid),
  ]);

  return db.runTransaction<RespondResult>(async (tx) => {
    const reqSnap = await tx.get(reqRef);
    const alreadyFriends = await tx.get(meRef.collection("friends").doc(fromUid));
    if (!reqSnap.exists && !alreadyFriends.exists) {
      return {ok: false, reason: "no_request"};
    }
    const now = FieldValue.serverTimestamp();
    tx.set(meRef.collection("friends").doc(fromUid), {
      uid: fromUid,
      handle: fromProfile.handle,
      displayName: fromProfile.displayName,
      avatarId: fromProfile.avatarId,
      since: now,
    });
    tx.set(fromRef.collection("friends").doc(meUid), {
      uid: meUid,
      handle: meProfile.handle,
      displayName: meProfile.displayName,
      avatarId: meProfile.avatarId,
      since: now,
    });
    tx.delete(reqRef);
    return {ok: true};
  });
}

// GET /friends: the caller's accepted friends + incoming pending requests.
export async function listFriends(uid: string): Promise<{
  friends: Array<{uid: string; handle: string; displayName: string; avatarId: string; since: number}>;
  requests: Array<{fromUid: string; handle: string; displayName: string; avatarId: string; at: number}>;
}> {
  const base = db.collection("users").doc(uid);
  const [fs, rs] = await Promise.all([
    base.collection("friends").get(),
    base.collection("friendRequests").get(),
  ]);
  const friends = fs.docs.map((d) => {
    const x = d.data();
    return {
      uid: (x.uid as string) ?? d.id,
      handle: (x.handle as string) ?? "",
      displayName: (x.displayName as string) ?? "Player",
      avatarId: (x.avatarId as string) ?? "avatar_01",
      since: millis(x.since),
    };
  });
  const requests = rs.docs.map((d) => {
    const x = d.data();
    return {
      fromUid: (x.fromUid as string) ?? d.id,
      handle: (x.handle as string) ?? "",
      displayName: (x.displayName as string) ?? "Player",
      avatarId: (x.avatarId as string) ?? "avatar_01",
      at: millis(x.at),
    };
  });
  return {friends, requests};
}

// GET /me/matches: the caller's match history, newest first, capped. Written by
// plan 11 at match finalize; empty until then.
export async function getMatchHistory(uid: string, limit = 50): Promise<MatchHistoryView[]> {
  const cap = Math.min(Math.max(limit, 1), 50);
  const snap = await db
    .collection("users").doc(uid).collection("matchHistory")
    .orderBy("endedAt", "desc")
    .limit(cap)
    .get();
  return snap.docs.map((d) => toHistory(d.data() as Record<string, unknown>));
}
