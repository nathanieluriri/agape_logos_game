// Local demo stack: fills the emulators with a believable player and friends
// for screen recordings. Every person here is fictional.
//   npm run demo:seed
import "./demo_env";
import {Timestamp} from "firebase-admin/firestore";
import {auth, db} from "../firebase";
import {TIERS, TIER_ORDER} from "../generation/config";
import {getStats} from "../pool/puzzle_pool";
import {runGeneration, defaultDeps} from "./generate";

export const DEMO_PASSWORD = "demo-pond-2026";
const HOUR = 60 * 60 * 1000;
const DAY = 24 * HOUR;
const now = Date.now();

interface Persona {
  uid: string;
  displayName: string;
  handle: string;
  avatarId: string;
  highestLevel: number;
  totalScore: number;
  coins: number;
  inventory?: Record<string, number>;
}

export const PLAYER: Persona = {
  uid: "demo-amara",
  displayName: "Amara",
  handle: "amara",
  avatarId: "avatar_03",
  highestLevel: 37,
  totalScore: 4210,
  coins: 1285,
  inventory: {
    hint: 4, freeze_letter: 2, fog: 3, scramble: 2, word_steal: 1,
    shield: 1, time_boost: 2, double_points: 1,
  },
};

export const FRIENDS: Persona[] = [
  {uid: "demo-tobi", displayName: "Tobi", handle: "tobi_plays", avatarId: "avatar_04", highestLevel: 41, totalScore: 4650, coins: 940,
    inventory: {freeze_letter: 3, fog: 2, scramble: 3, shield: 2, time_boost: 1}},
  {uid: "demo-kemi", displayName: "Kemi", handle: "kemi_k", avatarId: "avatar_02", highestLevel: 29, totalScore: 3120, coins: 610},
  {uid: "demo-zainab", displayName: "Zainab", handle: "zainab_z", avatarId: "avatar_05", highestLevel: 52, totalScore: 6034, coins: 2210},
  {uid: "demo-daniel", displayName: "Daniel", handle: "dan_words", avatarId: "avatar_06", highestLevel: 18, totalScore: 1870, coins: 330},
];

const REQUESTER: Persona = {
  uid: "demo-chidi", displayName: "Chidi", handle: "chidi_c", avatarId: "avatar_01",
  highestLevel: 12, totalScore: 1205, coins: 150,
};

// The first puzzle the player meets on Play, then the rest of the queue.
const UP_NEXT = process.env.DEMO_NEXT_PUZZLE ?? "CEIOV";
const DONE_LEVELS = 37;
const QUEUE = 20;

async function upsertAuth(p: Persona): Promise<void> {
  const email = `${p.handle.replace(/_/g, ".")}@example.com`;
  try {
    await auth.updateUser(p.uid, {email, password: DEMO_PASSWORD, displayName: p.displayName});
  } catch {
    await auth.createUser({uid: p.uid, email, password: DEMO_PASSWORD, displayName: p.displayName});
  }
}

async function upsertProfile(p: Persona, extra: Record<string, unknown> = {}): Promise<void> {
  await db.collection("users").doc(p.uid).set({
    uid: p.uid,
    displayName: p.displayName,
    displayNameLower: p.displayName.toLowerCase(),
    avatarId: p.avatarId,
    locale: "en",
    soundEnabled: true,
    musicEnabled: true,
    highestLevel: p.highestLevel,
    totalScore: p.totalScore,
    coins: p.coins,
    inventory: p.inventory ?? {},
    handle: p.handle,
    handleLower: p.handle.toLowerCase(),
    public: true,
    isGuest: false,
    createdAt: Timestamp.fromMillis(now - 60 * DAY),
    updatedAt: Timestamp.fromMillis(now - HOUR),
    ...extra,
  });
  await db.collection("usernames").doc(p.handle.toLowerCase()).set({uid: p.uid, at: Timestamp.fromMillis(now - 60 * DAY)});
}

async function clearSub(uid: string, sub: string): Promise<void> {
  const snap = await db.collection("users").doc(uid).collection(sub).get();
  await Promise.all(snap.docs.map((d) => d.ref.delete()));
}

async function befriend(a: Persona, b: Persona, since: number): Promise<void> {
  const row = (p: Persona) => ({uid: p.uid, handle: p.handle, displayName: p.displayName, avatarId: p.avatarId, since: Timestamp.fromMillis(since)});
  await db.collection("users").doc(a.uid).collection("friends").doc(b.uid).set(row(b));
  await db.collection("users").doc(b.uid).collection("friends").doc(a.uid).set(row(a));
}

async function assignments(): Promise<void> {
  const uid = PLAYER.uid;
  for (const sub of ["assignments", "draws", "puzzleResults", "levelResults"]) await clearSub(uid, sub);
  const next = await db.collection("puzzles").doc(UP_NEXT).get();
  if (!next.exists) throw new Error(`Puzzle ${UP_NEXT} is not in the pool. Run npm run seed first.`);
  const tier = next.data()?.tier as string;

  const done = await db.collection("puzzles").where("tier", "in", ["easy", "medium"]).limit(DONE_LEVELS).get();
  // The client plays its queue in tier order, then document-id order, and draws
  // more (easier tiers first) once fewer than 20 are unplayed, so the queue is
  // 20 puzzles of the same tier whose ids sort after the one to play first.
  const queue = await db.collection("puzzles").where("tier", "==", tier)
    .where("__name__", ">", db.collection("puzzles").doc(UP_NEXT)).orderBy("__name__").limit(QUEUE - 1).get();
  if (queue.size < QUEUE - 1) throw new Error(`Only ${queue.size + 1} ${tier} puzzles sort from ${UP_NEXT}; pick another.`);
  const col = db.collection("users").doc(uid).collection("assignments");
  const batch = db.batch();
  done.docs.forEach((d, i) => {
    const at = now - (DONE_LEVELS - i) * 1.4 * DAY;
    batch.set(col.doc(d.id), {puzzleId: d.id, tier: d.data().tier, assignedAt: at - HOUR, completed: true, completedAt: at});
  });
  const queued = [UP_NEXT, ...queue.docs.map((d) => d.id)];
  queued.forEach((id, i) => {
    batch.set(col.doc(id), {puzzleId: id, tier, assignedAt: now - HOUR + i, completed: false, completedAt: null});
  });
  await batch.commit();
}

async function history(): Promise<void> {
  await clearSub(PLAYER.uid, "matchHistory");
  const rows: [Persona, "win" | "loss" | "draw", number, number, number][] = [
    [FRIENDS[0], "win", 31, 27, 0.2],
    [FRIENDS[2], "loss", 22, 35, 1.1],
    [FRIENDS[1], "win", 28, 19, 2.3],
    [FRIENDS[0], "loss", 24, 26, 3.4],
    [FRIENDS[3], "win", 30, 14, 5.0],
    [FRIENDS[1], "draw", 21, 21, 6.2],
  ];
  const col = db.collection("users").doc(PLAYER.uid).collection("matchHistory");
  await Promise.all(rows.map(([opp, result, score, oppScore, daysAgo], i) => {
    const matchId = `demo-history-${i + 1}`;
    return col.doc(matchId).set({
      matchId, opponentUid: opp.uid, opponentName: opp.displayName, result, score,
      opponentScore: oppScore, endedAt: now - daysAgo * DAY,
      settings: {difficulty: "medium", durationSec: 120, rackSize: 7, theme: null, mode: "live"},
    });
  }));
}

async function pool(): Promise<void> {
  const stats = await getStats();
  if (stats.perTier.expert > 0) return;
  await runGeneration(TIER_ORDER.map((tier) => ({tier, count: TIERS[tier].poolTarget})), defaultDeps());
}

async function main(): Promise<void> {
  await pool();
  for (const p of [PLAYER, ...FRIENDS, REQUESTER]) {
    await upsertAuth(p);
    await clearSub(p.uid, "friends");
    await clearSub(p.uid, "friendRequests");
    await clearSub(p.uid, "challenges");
  }
  await upsertProfile(PLAYER, {
    rewards: {
      coinClaimAt: Timestamp.fromMillis(now - 20 * HOUR),
      powerupClaimAt: Timestamp.fromMillis(now - 2 * DAY),
      powerupBag: [],
      lastPowerupId: "fog",
    },
  });
  for (const f of [...FRIENDS, REQUESTER]) await upsertProfile(f);
  await Promise.all(FRIENDS.map((f, i) => befriend(PLAYER, f, now - (40 - i * 6) * DAY)));
  await db.collection("users").doc(PLAYER.uid).collection("friendRequests").doc(REQUESTER.uid).set({
    fromUid: REQUESTER.uid, handle: REQUESTER.handle, displayName: REQUESTER.displayName,
    avatarId: REQUESTER.avatarId, at: Timestamp.fromMillis(now - 3 * HOUR),
  });
  await assignments();
  await history();
  // eslint-disable-next-line no-console
  console.log(`demo seeded: ${PLAYER.displayName} (${PLAYER.handle}@example.com), up next ${UP_NEXT}`);
}

main().then(
  () => process.exit(0),
  (err) => {
    // eslint-disable-next-line no-console
    console.error(err);
    process.exit(1);
  },
);
