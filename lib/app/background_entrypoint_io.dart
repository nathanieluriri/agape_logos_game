import 'background_sync.dart';

/// The Android WorkManager background entry point (a top-level
/// `@pragma('vm:entry-point')` function; references stay top-level so the engine
/// can resolve the callback handle).
const void Function() backgroundFlushEntryPoint = callbackDispatcher;
