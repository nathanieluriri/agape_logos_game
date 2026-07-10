import {FieldValue} from "firebase-admin/firestore";
import {db} from "../firebase";
import {shuffle} from "../generation/random";
import {POWERUP_ITEM_ID, POWERUP_DURATION_MS, wordScore} from "./match_scoring";
import {settleMatch} from "./match_finalize";
import {HttpError} from "../middleware/http_error";
import type {PowerupKind} from "../schemas/matches";

export interface PowerupResult {
  ok: boolean;
  reason?: string;
}

// Fires a powerup at the opponent: spends one from the caller's inventory and
// writes one append-only event the target's client reacts to live. The whole
// thing is one transaction, so a 402/409 spends nothing. Idempotent per event id
// (the idempotency-key): a replay returns ok without re-spending.
// PLAN: freeze/fog are input-limiting signals the client enforces (they grant no
// points, so the cheat value of ignoring them is low; plan 10 section 9).
// scramble and word_steal change server state, so they are enforced regardless.
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
  if (!(settled.status === "active" && now >= settled.startedAt && now < settled.endsAt)) {
    throw new HttpError(409, "match not active");
  }
  const targetUid = settled.participants.find((p) => p !== uid);
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
    const tRackSnap = await tx.get(targetRackRef);
    if (evSnap.exists) return {ok: true, reason: "replay"};

    const inv = (userSnap.data()?.inventory ?? {}) as Record<string, number>;
    if ((inv[itemId] ?? 0) < 1) throw new HttpError(402, "powerup not owned");

    const tRack = tRackSnap.data() as {letters: string[]; foundWords: string[]} | undefined;
    const payload: Record<string, unknown> = {};
    const expiresAt = POWERUP_DURATION_MS[kind] > 0 ? now + POWERUP_DURATION_MS[kind] : 0;

    if (kind === "letter_freeze") {
      const size = tRack?.letters.length ?? 0;
      payload.letterIndex = size > 0 ? Math.floor(Math.random() * size) : 0;
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
      tx.update(matchRef, {
        [`players.${targetUid}.score`]: FieldValue.increment(-points),
        [`players.${targetUid}.wordsFound`]: FieldValue.increment(-1),
        [`players.${uid}.score`]: FieldValue.increment(points),
        [`players.${uid}.wordsFound`]: FieldValue.increment(1),
      });
    }
    // fog_bank: payload stays {} (pure signal, timed by expiresAt).

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
    return {ok: true};
  });
}
