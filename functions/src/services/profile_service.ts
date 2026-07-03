import {FieldValue, Timestamp} from "firebase-admin/firestore";
import {db} from "../firebase";
import {DEFAULT_PROFILE, ProfilePatch} from "../schemas/profile";

export interface ProfileResponse {
  uid: string;
  displayName: string;
  avatarId: string;
  locale: string;
  soundEnabled: boolean;
  musicEnabled: boolean;
  highestLevel: number;
  totalScore: number;
  coins: number;
  inventory: Record<string, number>;
  createdAt: number;
  updatedAt: number;
}

function toMillis(value: unknown): number {
  return value instanceof Timestamp ? value.toMillis() : 0;
}

function serialize(uid: string, data: Record<string, unknown>): ProfileResponse {
  return {
    uid,
    displayName: (data.displayName as string) ?? DEFAULT_PROFILE.displayName,
    avatarId: (data.avatarId as string) ?? DEFAULT_PROFILE.avatarId,
    locale: (data.locale as string) ?? DEFAULT_PROFILE.locale,
    soundEnabled: (data.soundEnabled as boolean) ?? DEFAULT_PROFILE.soundEnabled,
    musicEnabled: (data.musicEnabled as boolean) ?? DEFAULT_PROFILE.musicEnabled,
    highestLevel: (data.highestLevel as number) ?? DEFAULT_PROFILE.highestLevel,
    totalScore: (data.totalScore as number) ?? DEFAULT_PROFILE.totalScore,
    coins: (data.coins as number) ?? DEFAULT_PROFILE.coins,
    inventory: (data.inventory as Record<string, number>) ?? {},
    createdAt: toMillis(data.createdAt),
    updatedAt: toMillis(data.updatedAt),
  };
}

// Reads users/{uid}; creates it with defaults in a transaction if absent so
// concurrent first reads do not double-create. createdAt is set only once.
export async function getOrCreateProfile(uid: string): Promise<ProfileResponse> {
  const ref = db.collection("users").doc(uid);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) {
      tx.set(ref, {
        ...DEFAULT_PROFILE,
        uid,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
  });
  const snap = await ref.get();
  return serialize(uid, (snap.data() ?? {}) as Record<string, unknown>);
}

// Returns just the caller's coin balance, provisioning the profile on first
// read (same guarantee as getOrCreateProfile) so a brand-new user gets 0 coins
// rather than a 404.
export async function getCoins(uid: string): Promise<{coins: number}> {
  const profile = await getOrCreateProfile(uid);
  return {coins: profile.coins};
}

// Ensures the profile exists, merges the validated patch, and bumps updatedAt.
export async function updateProfile(
  uid: string,
  patch: ProfilePatch,
): Promise<ProfileResponse> {
  await getOrCreateProfile(uid);
  const ref = db.collection("users").doc(uid);
  await ref.set({...patch, updatedAt: FieldValue.serverTimestamp()}, {merge: true});
  const snap = await ref.get();
  return serialize(uid, (snap.data() ?? {}) as Record<string, unknown>);
}
