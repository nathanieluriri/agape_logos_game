import {getMessaging} from "firebase-admin/messaging";
import {FieldValue} from "firebase-admin/firestore";
import {db} from "../firebase";

// Which tokens the transport says are permanently dead, so they can be pruned.
// PURE function - this is the unit-testable core.
export function pruneInvalid(
  responses: {success: boolean; error?: {code?: string}}[],
  tokens: string[],
): string[] {
  const dead: string[] = [];
  responses.forEach((r, i) => {
    const code = r.error?.code;
    if (!r.success && (
      code === "messaging/registration-token-not-registered" ||
      code === "messaging/invalid-registration-token"
    )) dead.push(tokens[i]);
  });
  return dead;
}

// Fan a notification out to every device the user registered, then drop the dead
// tokens. A user with NO devices is a no-op, never an error: push is best-effort
// on top of the live listener, not the source of truth.
export async function sendToUser(
  uid: string,
  payload: {title: string; body: string; data: Record<string, string>},
): Promise<void> {
  const snap = await db.collection("users").doc(uid).collection("devices").get();
  const tokens = snap.docs.map((d) => d.id);
  if (tokens.length === 0) return;
  const res = await getMessaging().sendEachForMulticast({
    tokens,
    notification: {title: payload.title, body: payload.body},
    data: payload.data,
  });
  const dead = pruneInvalid(res.responses as never, tokens);
  await Promise.all(dead.map((t) =>
    db.collection("users").doc(uid).collection("devices").doc(t).delete()));
}

export async function registerDevice(uid: string, token: string, platform: string): Promise<void> {
  await db.collection("users").doc(uid).collection("devices").doc(token)
    .set({token, platform, at: FieldValue.serverTimestamp()});
}

export async function unregisterDevice(uid: string, token: string): Promise<void> {
  await db.collection("users").doc(uid).collection("devices").doc(token).delete();
}
