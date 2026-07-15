import {FieldValue} from "firebase-admin/firestore";
import {db} from "../firebase";
import {shuffle} from "../generation/random";
import {
  OFFENSIVE_KINDS,
  POWERUP_DURATION_MS,
  POWERUP_ITEM_ID,
  TIME_BOOST_MS,
  maxBonus,
  wordScore,
} from "./match_scoring";
import {settleMatch} from "./match_finalize";
import {HttpError} from "../middleware/http_error";
import type {PowerupKind} from "../schemas/matches";
import type {ActiveEffect, MatchData} from "./match_types";

export interface PowerupResult {
  ok: boolean;
  reason?: string;
  serverNow: number;
}

// Drops expired entries. expiresAt === 0 means "armed until consumed" and
// never expires by time alone.
function pruneEffects(list: ActiveEffect[] | undefined, now: number): ActiveEffect[] {
  return (list ?? []).filter((e) => e.expiresAt === 0 || e.expiresAt > now);
}

// Fires a powerup: spends one from the caller's inventory and writes one
// append-only event the target's client reacts to live, plus (for the timed/
// armed kinds) an entry in the match doc's activeEffects map, keyed by the uid
// the effect acts ON. The whole thing is one transaction, so a 402/409 spends
// nothing. Idempotent per event id (the idempotency-key): a replay returns ok
// without re-spending. A "warded" 409 (word_steal vs combo_lock) also spends
// nothing and appends no event; the route maps it to a structured 200 body.
export async function firePowerup(
  uid: string,
  matchId: string,
  kind: PowerupKind,
  eventId: string,
): Promise<PowerupResult> {
  const settled = await settleMatch(matchId);
  if (!settled) throw new HttpError(404, "match not found");
  if (!settled.participants.includes(uid)) throw new HttpError(403, "not a participant");
  const now = Date.now();
  const boostedEndsAt = settled.endsAt + maxBonus(settled);
  if (!(settled.status === "active" && now >= settled.startedAt && now < boostedEndsAt)) {
    throw new HttpError(409, "match not active");
  }
  const offensive = OFFENSIVE_KINDS.has(kind);
  const targetUid = offensive ? settled.participants.find((p) => p !== uid) : uid;
  if (!targetUid) throw new HttpError(409, "no opponent");

  const matchRef = db.collection("matches").doc(matchId);
  const userRef = db.collection("users").doc(uid);
  const eventRef = matchRef.collection("events").doc(eventId);
  const targetRackRef = matchRef.collection("racks").doc(targetUid);
  const itemId = POWERUP_ITEM_ID[kind];
  const participants = settled.participants;

  return db.runTransaction<PowerupResult>(async (tx) => {
    // Reads first.
    const evSnap = await tx.get(eventRef);
    const userSnap = await tx.get(userRef);
    const mSnap = await tx.get(matchRef);
    const tRackSnap = offensive ? await tx.get(targetRackRef) : undefined;
    if (evSnap.exists) return {ok: true, reason: "replay", serverNow: now};

    const inv = (userSnap.data()?.inventory ?? {}) as Record<string, number>;
    if ((inv[itemId] ?? 0) < 1) throw new HttpError(402, "powerup not owned");

    const m = mSnap.data() as MatchData;
    const effects = m.activeEffects ?? {};
    const mine = pruneEffects(effects[uid], now);
    const theirs = pruneEffects(effects[targetUid], now);

    // A shield armed on the target consumes itself and blocks any offensive
    // kind entirely: no rack/board/timer change, just a "blocked" event. The
    // caster still spends the item (the item did its job: it got blocked).
    if (offensive) {
      const shieldIdx = theirs.findIndex((e) => e.kind === "shield");
      if (shieldIdx >= 0) {
        theirs.splice(shieldIdx, 1);
        tx.update(matchRef, {[`activeEffects.${targetUid}`]: theirs});
        tx.update(userRef, {[`inventory.${itemId}`]: FieldValue.increment(-1)});
        tx.set(eventRef, {
          id: eventId,
          at: now,
          byUid: uid,
          targetUid,
          kind: "blocked",
          payload: {originalKind: kind},
          expiresAt: 0,
          participants,
        });
        return {ok: true, reason: "blocked", serverNow: now};
      }
      if (kind === "word_steal" && theirs.some((e) => e.kind === "combo_lock")) {
        // Aborts the transaction: nothing is spent or written.
        throw new HttpError(409, "warded");
      }
    } else {
      if (kind === "shield" && mine.some((e) => e.kind === "shield")) {
        throw new HttpError(409, "shield already armed");
      }
    }

    const tRack = tRackSnap?.data() as {letters: string[]; foundWords: string[]} | undefined;
    const payload: Record<string, unknown> = {};
    const durationMs = POWERUP_DURATION_MS[kind];
    const expiresAt = durationMs > 0 ? now + durationMs : 0;
    const matchUpdate: Record<string, unknown> = {};

    if (kind === "letter_freeze") {
      const letters = tRack?.letters ?? [];
      payload.letter = letters.length > 0 ? letters[Math.floor(Math.random() * letters.length)] : "";
      theirs.push({kind, byUid: uid, startedAt: now, expiresAt, payload});
    } else if (kind === "fog_bank") {
      theirs.push({kind, byUid: uid, startedAt: now, expiresAt, payload});
    } else if (kind === "scramble") {
      if (tRack) {
        const reordered = shuffle(tRack.letters, () => Math.random());
        payload.letters = reordered;
        tx.update(targetRackRef, {letters: reordered});
      }
    } else if (kind === "word_steal") {
      const stealable = tRack?.foundWords ?? [];
      if (stealable.length === 0) throw new HttpError(409, "nothing to steal");
      const word = stealable[stealable.length - 1];
      const points = wordScore(word);
      payload.word = word;
      payload.points = points;
      // Remove from the target's rack + score; credit the caller. The stolen
      // word is NOT added to the caller's rack (it is not formable from their
      // letters); only the match scores move. The event tells the target's
      // client to drop the word from its board.
      tx.update(targetRackRef, {foundWords: FieldValue.arrayRemove(word)});
      matchUpdate[`players.${targetUid}.score`] = FieldValue.increment(-points);
      matchUpdate[`players.${targetUid}.wordsFound`] = FieldValue.increment(-1);
      matchUpdate[`players.${uid}.score`] = FieldValue.increment(points);
      matchUpdate[`players.${uid}.wordsFound`] = FieldValue.increment(1);
    } else if (kind === "shield") {
      mine.push({kind, byUid: uid, startedAt: now, expiresAt: 0, payload});
    } else if (kind === "time_boost") {
      matchUpdate[`players.${uid}.endsAtBonusMs`] = FieldValue.increment(TIME_BOOST_MS);
    } else if (kind === "double_points" || kind === "combo_lock") {
      mine.push({kind, byUid: uid, startedAt: now, expiresAt, payload});
    }

    // Always write back the (possibly pruned, possibly appended) arrays for
    // both the caster and the target, so an expired entry never lingers past
    // the next powerup fired by either side of it.
    if (uid !== targetUid) {
      matchUpdate[`activeEffects.${uid}`] = mine;
      matchUpdate[`activeEffects.${targetUid}`] = theirs;
    } else {
      matchUpdate[`activeEffects.${uid}`] = mine;
    }

    tx.update(matchRef, matchUpdate);

    // Spend one from inventory and append the event.
    tx.update(userRef, {[`inventory.${itemId}`]: FieldValue.increment(-1)});
    tx.set(eventRef, {
      id: eventId,
      at: now,
      byUid: uid,
      targetUid,
      kind,
      payload,
      expiresAt,
      participants, // denormalized for the events read rule (deviation 1)
    });
    return {ok: true, serverNow: now};
  });
}
