/// Public VAPID key ("Web Push certificate") required by `getToken` on web.
///
/// This value is NOT in the repo and cannot be generated from code. Get it from
/// the Firebase console: Project Settings > Cloud Messaging > Web configuration >
/// Web Push certificates > "Key pair" (the public key string). Paste it here.
///
/// While this is empty, web push registration is a clean no-op (see
/// `push_service_web.dart`). Android push does NOT use this key and works fully
/// regardless.
const String kWebPushVapidKey = '';
