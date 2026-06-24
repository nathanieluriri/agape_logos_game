/// No background WorkManager entry point off-Android (web/desktop). The web build
/// resolves to this file, keeping `workmanager`/`dart:io` out of the bundle.
const void Function()? backgroundFlushEntryPoint = null;
