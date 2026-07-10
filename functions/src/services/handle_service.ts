import {FieldValue} from "firebase-admin/firestore";
import {db} from "../firebase";

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

// Resolves a handle (any casing) to a uid via the usernames index, or null.
export async function uidForHandle(handle: string): Promise<string | null> {
  const snap = await db.collection("usernames").doc(handle.toLowerCase()).get();
  return snap.exists ? ((snap.data()?.uid as string) ?? null) : null;
}
