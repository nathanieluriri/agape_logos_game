// Selects the platform-appropriate Drift connection at compile time:
// native (`sqlite3_flutter_libs`) on Android, WASM in the browser.
export 'connection_stub.dart'
    if (dart.library.io) 'connection_native.dart'
    if (dart.library.js_interop) 'connection_web.dart';
