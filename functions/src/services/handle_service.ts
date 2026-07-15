import {FieldValue} from "firebase-admin/firestore";
import {db} from "../firebase";

// Same shape enforced by POST /friends/request's handle validation, so a
// handle you can claim here is always a handle a friend can search for.
export const HANDLE_RE = /^[A-Za-z0-9_]{3,20}$/;

export function isValidHandle(h: string): boolean {
  return HANDLE_RE.test(h);
}

// Turns a free-form display name into a handle base: lowercase, keep letters and
// digits, drop everything else, clamp to 15 chars, and fall back to "player"
// when nothing usable remains (a name that is all emoji or punctuation).
export function slugifyHandle(displayName: string): string {
  const slug = (displayName || "")
    .toLowerCase()
    .replace(/[^a-z0-9]/g, "")
    .slice(0, 15);
  return slug.length >= 3 ? slug : "player";
}

// A short numeric discriminator appended to a base when the bare handle is taken.
function discriminator(): string {
  return String(Math.floor(1000 + Math.random() * 9000));
}

// Allocates a unique handle for [uid] and reserves usernames/{handleLower}.
// Idempotent: if a candidate index doc already maps to this uid it is accepted,
// so a re-run returns the same handle. Tries the bare slug first, then
// slug+discriminator a few times, then a uid-derived last resort that can only
// belong to this user. Writes handle + handleLower onto the user doc.
export async function ensureHandle(
  uid: string,
  displayName: string,
): Promise<{handle: string; handleLower: string}> {
  const base = slugifyHandle(displayName);
  const uidSuffix = uid.slice(0, 6).toLowerCase().replace(/[^a-z0-9]/g, "");
  const candidates = [
    base,
    `${base}${discriminator()}`,
    `${base}${discriminator()}`,
    `${base}${discriminator()}`,
    `${base}${uidSuffix}`,
  ];
  for (const candidate of candidates) {
    const handleLower = candidate.toLowerCase();
    const idxRef = db.collection("usernames").doc(handleLower);
    const userRef = db.collection("users").doc(uid);
    const claimed = await db.runTransaction(async (tx) => {
      const idxSnap = await tx.get(idxRef);
      if (idxSnap.exists) return idxSnap.data()?.uid === uid; // already ours?
      tx.set(idxRef, {uid, at: FieldValue.serverTimestamp()});
      tx.set(userRef, {handle: candidate, handleLower}, {merge: true});
      return true;
    });
    if (claimed) return {handle: candidate, handleLower};
  }
  // Astronomically unlikely fallback: a fully uid-derived, deterministic handle.
  const fallback = `player${uid.slice(0, 8).toLowerCase().replace(/[^a-z0-9]/g, "")}`;
  await db.runTransaction(async (tx) => {
    tx.set(db.collection("usernames").doc(fallback), {uid, at: FieldValue.serverTimestamp()});
    tx.set(db.collection("users").doc(uid), {handle: fallback, handleLower: fallback}, {merge: true});
  });
  return {handle: fallback, handleLower: fallback};
}

// Claims [desired] as [uid]'s new handle, releasing whatever handle they held
// before. Runs as a single transaction so two users racing onto the same
// handle cannot both win (a non-transactional check-then-write would allow
// that). Re-claiming your own current handle is a no-op success.
export async function setHandle(
  uid: string,
  desired: string,
): Promise<{ok: true; handle: string} | {ok: false; reason: "taken" | "invalid"}> {
  if (!isValidHandle(desired)) return {ok: false, reason: "invalid"};

  const lower = desired.toLowerCase();
  const newRef = db.collection("usernames").doc(lower);
  const userRef = db.collection("users").doc(uid);

  const result = await db.runTransaction(async (tx) => {
    // All reads before any write.
    const newSnap = await tx.get(newRef);
    if (newSnap.exists && newSnap.data()?.uid !== uid) {
      return {ok: false as const, reason: "taken" as const};
    }
    const userSnap = await tx.get(userRef);
    const prevHandleLower = userSnap.data()?.handleLower as string | undefined;

    tx.set(newRef, {uid, at: FieldValue.serverTimestamp()});
    if (prevHandleLower && prevHandleLower !== lower) {
      tx.delete(db.collection("usernames").doc(prevHandleLower));
    }
    tx.set(userRef, {handle: desired, handleLower: lower, updatedAt: FieldValue.serverTimestamp()}, {merge: true});
    return {ok: true as const, handle: desired};
  });

  // The claim is already DURABLE at this point. The fan-out is a best-effort
  // repair of denormalized copies, so a failure here must not be reported to the
  // caller as a failed claim: the handle IS theirs, and telling them otherwise
  // would send them round to claim it again. Log it and move on; the next claim
  // (or any friend-list write) refreshes the copies.
  if (result.ok) {
    try {
      await fanOutHandle(uid, desired);
    } catch (e) {
      console.error(`handle fan-out failed for ${uid}`, e);
    }
  }
  return result;
}

// The handle is denormalized in three places so those surfaces render without an
// extra read: each friend edge (users/{friendUid}/friends/{uid}), each friend
// request I have sent (users/{toUid}/friendRequests/{myUid}, keyed off fromUid),
// and each challenge I have sent (users/{toUid}/challenges/{matchId}, keyed off
// byUid). A claim RELEASES the old handle, so a stale copy is not just wrong: a
// stranger could re-claim it, and someone acting on the stale label would reach
// the wrong person. After the claim commits we push the new handle onto all three.
// Runs outside the transaction (a transaction cannot run these queries); each set
// is small and bounded (a user's own friends / outstanding invites), and the
// whole thing is best-effort per its caller. Accept paths key off uid, so a
// missed copy is cosmetic, never a misroute.
async function fanOutHandle(uid: string, handle: string): Promise<void> {
  const [friends, sentRequests, sentChallenges] = await Promise.all([
    db.collection("users").doc(uid).collection("friends").get(),
    db.collectionGroup("friendRequests").where("fromUid", "==", uid).get(),
    db.collectionGroup("challenges").where("byUid", "==", uid).get(),
  ]);

  const batch = db.batch();
  let writes = 0;
  for (const doc of friends.docs) {
    // The reciprocal edge: the friend's copy of me.
    batch.set(
      db.collection("users").doc(doc.id).collection("friends").doc(uid),
      {handle},
      {merge: true},
    );
    writes++;
  }
  for (const doc of sentRequests.docs) {
    batch.set(doc.ref, {handle}, {merge: true});
    writes++;
  }
  for (const doc of sentChallenges.docs) {
    batch.set(doc.ref, {handle}, {merge: true});
    writes++;
  }
  if (writes > 0) await batch.commit();
}

// Resolves a handle (any casing) to a uid via the usernames index, or null.
export async function uidForHandle(handle: string): Promise<string | null> {
  const snap = await db.collection("usernames").doc(handle.toLowerCase()).get();
  return snap.exists ? ((snap.data()?.uid as string) ?? null) : null;
}
