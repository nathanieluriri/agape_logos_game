// Picks the low-level vibration primitives at compile time, exactly like
// `core/offline/sync_scheduler_factory.dart` and `core/storage/connection/connection.dart`:
//  - Android (dart.library.io): the `vibration` plugin, with real amplitude control.
//  - Web (dart.library.js_interop): the browser Vibration API (`navigator.vibrate`).
//  - Anything else: safe no-ops (see the stub for why it does not throw).
// All three files expose the SAME three top-level functions, so `FlutterHapticService`
// delegates to them without knowing the platform.
export 'haptic_platform_stub.dart'
    if (dart.library.io) 'haptic_platform_android.dart'
    if (dart.library.js_interop) 'haptic_platform_web.dart';
