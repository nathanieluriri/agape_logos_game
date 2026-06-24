// Selects the platform Google sign-in implementation at compile time:
// native (google_sign_in interactive auth) on Android, popup on web.
export 'google_auth_stub.dart'
    if (dart.library.io) 'google_auth_native.dart'
    if (dart.library.js_interop) 'google_auth_web.dart';
