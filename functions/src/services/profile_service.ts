import {FieldValue, Timestamp} from "firebase-admin/firestore";
import {db} from "../firebase";
import {DEFAULT_PROFILE, ProfilePatch} from "../schemas/profile";
import {ensureHandle} from "./handle_service";

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
  handle: string;
  public: boolean;
  isGuest: boolean;
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
    handle: (data.handle as string) ?? "",
    public: (data.public as boolean) ?? false,
    isGuest: (data.isGuest as boolean) ?? false,
    createdAt: toMillis(data.createdAt),
    updatedAt: toMillis(data.updatedAt),
  };
}

// Reads users/{uid}; creates it with defaults in a transaction if absent so
// concurrent first reads do not double-create. createdAt is set only once. On
// first provision it also seeds displayNameLower (for prefix search) and isGuest
// (from the caller when known), then allocates a stable, unique @handle.
export async function getOrCreateProfile(
  uid: string,
  opts?: {isGuest?: boolean},
): Promise<ProfileResponse> {
  const ref = db.collection("users").doc(uid);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) {
      tx.set(ref, {
        ...DEFAULT_PROFILE,
        uid,
        isGuest: opts?.isGuest ?? false,
        displayNameLower: DEFAULT_PROFILE.displayName.toLowerCase(),
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
  });
  // Allocate the searchable handle on first provision (idempotent thereafter).
  const pre = await ref.get();
  const preData = (pre.data() ?? {}) as Record<string, unknown>;
  if (!preData.handle) {
    await ensureHandle(uid, (preData.displayName as string) ?? DEFAULT_PROFILE.displayName);
  }
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
// Mirrors a lowercased displayNameLower whenever the name changes (search).
export async function updateProfile(
  uid: string,
  patch: ProfilePatch,
): Promise<ProfileResponse> {
  await getOrCreateProfile(uid);
  const ref = db.collection("users").doc(uid);
  const extra: Record<string, unknown> = {};
  if (typeof patch.displayName === "string") {
    extra.displayNameLower = patch.displayName.toLowerCase();
  }
  await ref.set(
    {...patch, ...extra, updatedAt: FieldValue.serverTimestamp()},
    {merge: true},
  );
  const snap = await ref.get();
  return serialize(uid, (snap.data() ?? {}) as Record<string, unknown>);
}
