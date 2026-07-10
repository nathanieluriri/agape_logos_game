import {db} from "../firebase";
import {Rng} from "../generation/random";

// Reduced, unambiguous join-code alphabet (no I/O/Q/X/Z) so codes read cleanly
// aloud and stay wheel-friendly. FROZEN by plan 10 section 8.6.
export const kMatchCodeAlphabet = "ABCDEFGHJKLMNPRSTUVWY";
export const kMatchCodeLength = 4;

// With ~21^4 (194k) combinations and few live lobbies, a collision is rare; a
// handful of retries is plenty before giving up.
const kMaxReserveAttempts = 8;

// Pure, unit-testable generator: kMatchCodeLength characters from the alphabet
// using the injected rng. Deterministic for a seeded rng.
export function generateCode(rng: Rng = () => Math.random()): string {
  let code = "";
  for (let i = 0; i < kMatchCodeLength; i++) {
    const idx = Math.min(
      kMatchCodeAlphabet.length - 1,
      Math.floor(rng() * kMatchCodeAlphabet.length),
    );
    code += kMatchCodeAlphabet[idx];
  }
  return code;
}

// Reserves a unique code for [matchId] by creating matchCodes/{CODE} in a
// transaction that fails if the doc already exists. Retries on collision.
// Returns the reserved code; throws if no free code is found.
export async function reserveCode(
  matchId: string,
  rng: Rng = () => Math.random(),
): Promise<string> {
  for (let attempt = 0; attempt < kMaxReserveAttempts; attempt++) {
    const code = generateCode(rng);
    const ref = db.collection("matchCodes").doc(code);
    const reserved = await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (snap.exists && (snap.data()?.active ?? false)) return false;
      tx.set(ref, {matchId, createdAt: Date.now(), active: true});
      return true;
    });
    if (reserved) return code;
  }
  throw new Error("could not reserve a unique match code");
}

// Marks a code inactive (lobby cancelled / match finished / stale). Kept as a
// tombstone rather than deleted so an in-flight join sees "closed", not
// "unknown", and the code can be recycled later.
export async function releaseCode(code: string): Promise<void> {
  await db.collection("matchCodes").doc(code).set({active: false}, {merge: true});
}

// Resolves a (case-insensitive) code to an ACTIVE matchId, or null.
export async function lookupCode(code: string): Promise<string | null> {
  const snap = await db.collection("matchCodes").doc(code.toUpperCase()).get();
  if (!snap.exists) return null;
  const data = snap.data() as {matchId: string; active: boolean};
  return data.active ? data.matchId : null;
}
