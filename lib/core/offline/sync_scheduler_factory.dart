// Picks the platform implementation of `createSyncScheduler` at compile time.
export 'sync_scheduler_stub.dart'
    if (dart.library.io) 'sync_scheduler_android.dart'
    if (dart.library.js_interop) 'sync_scheduler_web.dart';
