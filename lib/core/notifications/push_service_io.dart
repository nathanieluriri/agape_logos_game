import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../logging/app_logger.dart';
import '../network/api_client.dart';
import 'push_service.dart';

/// Android push implementation. Requests notification permission (Android 13+
/// runtime prompt), mints the FCM token via `getToken()` (no VAPID key needed on
/// Android), and keeps the backend registry in sync on token rotation.
PushService createPushService(ApiClient api) =>
    _AndroidPushService(DeviceRegistrar(api, platform: 'android'));

class _AndroidPushService implements PushService {
  _AndroidPushService(this._registrar);

  final DeviceRegistrar _registrar;

  String? _token;
  StreamSubscription<String>? _refreshSub;

  @override
  Future<void> registerForUser(String uid, {bool prompt = true}) async {
    final messaging = FirebaseMessaging.instance;
    // Lazy permission rule: only the Friends-page path (prompt: true) may show
    // the system dialog. The sign-in path (prompt: false) just reads the current
    // status so a restored session at cold start never triggers a prompt.
    final settings = prompt
        ? await messaging.requestPermission()
        : await messaging.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.denied ||
        settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      logger.info('Push permission not granted; skipping device registration');
      return;
    }

    final token = await messaging.getToken();
    _token = token;
    await _registrar.register(token);

    // Re-POST when FCM rotates the token so the registry never goes stale.
    _refreshSub ??= messaging.onTokenRefresh.listen((newToken) {
      _token = newToken;
      unawaited(_registrar.register(newToken));
    });
  }

  @override
  Future<void> unregister() async {
    await _refreshSub?.cancel();
    _refreshSub = null;
    final token = _token ?? await FirebaseMessaging.instance.getToken();
    await _registrar.unregister(token);
    await FirebaseMessaging.instance.deleteToken();
    _token = null;
  }
}
