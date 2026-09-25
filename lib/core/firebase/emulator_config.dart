/// Local demo stack: `--dart-define=USE_FIREBASE_EMULATORS=true` points Auth
/// and Firestore at the emulators in firebase.json instead of the live project.
const bool kUseFirebaseEmulators = bool.fromEnvironment(
  'USE_FIREBASE_EMULATORS',
);

const String kEmulatorHost = String.fromEnvironment(
  'EMULATOR_HOST',
  defaultValue: 'localhost',
);
