import * as admin from "firebase-admin";

// Initializes the Admin SDK once. Under the emulators, the host env vars
// (FIRESTORE_EMULATOR_HOST / FIREBASE_AUTH_EMULATOR_HOST / GCLOUD_PROJECT) are
// picked up automatically with no explicit config.
if (admin.apps.length === 0) {
  admin.initializeApp();
}

export const db = admin.firestore();
export const auth = admin.auth();
