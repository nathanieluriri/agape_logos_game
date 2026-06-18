/// Resolves the WorkManager background entry point per platform. Native exposes
/// the real `callbackDispatcher`; web/other has none. The conditional import keeps
/// `workmanager`/`dart:io` out of the web build.
library;

export 'background_entrypoint_stub.dart'
    if (dart.library.io) 'background_entrypoint_io.dart';
