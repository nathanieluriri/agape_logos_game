import {onRequest} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {createApp} from "./app";
import {sweepStaleMatches} from "./services/match_finalize";
import {sendToUser} from "./services/messaging_service";

// Scales to zero: no always-on cost. The first-login slowness was dominated by
// the draw reading every puzzle id in a tier (~900 reads); that is now a bounded
// random-window query (see assignment_service), so a cold start (Node 22 +
// express + firebase-admin init + token-key fetch) is the only remaining spike
// and it hits just the first request after an idle period.
//
// If first-login latency becomes a complaint under real traffic, set
// minInstances: 1 to keep one container warm. That costs a few dollars a month
// (idle-instance billing) and removes the cold start entirely.
//
// 512 MiB gives headroom for the batch encrypt; 30s is plenty for the bounded
// draw. Adequate for multiplayer: writes are small transactions, and realtime
// reads are client-side Firestore listeners that never hit this function.
export const api = onRequest(
  {
    region: "us-central1",
    minInstances: 0,
    memory: "512MiB",
    timeoutSeconds: 30,
    concurrency: 80,
  },
  createApp(),
);

// Safety net for match lifecycle: finalize is normally LAZY (settleMatch runs on
// every read/submit/powerup). This scheduled sweep catches matches nobody touched
// after their timer expired, and cancels stale lobbies (freeing their join codes).
// Small function, minInstances 0 (a 2-minute cadence tolerates a cold start).
export const matchSweep = onSchedule(
  {
    region: "us-central1",
    schedule: "every 2 minutes",
    memory: "256MiB",
    timeoutSeconds: 60,
  },
  async () => {
    await sweepStaleMatches();
  },
);

// Push when a friend request lands. The in-app listener already shows it live;
// this exists for the app-CLOSED case, so it is best-effort and never throws.
export const onFriendRequest = onDocumentCreated(
  {region: "us-central1", document: "users/{uid}/friendRequests/{fromUid}"},
  async (event) => {
    const d = event.data?.data();
    if (!d) return;
    const uid = event.params.uid as string;
    try {
      await sendToUser(uid, {
        title: "New friend request",
        body: `${d.displayName ?? "Someone"} wants to be friends`,
        data: {type: "friend_request", fromUid: String(d.fromUid ?? "")},
      });
    } catch (e) {
      console.error(`friend-request push failed for ${uid}`, e);
    }
  },
);
