import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../logging/app_logger.dart';
import '../network/api_client.dart';
import 'push_config.dart';
import 'push_service.dart';

/// Web push implementation. `getToken` on web requires the VAPID key
/// ([kWebPushVapidKey]); when it is empty this is a clean no-op so the app never
/// calls `getToken` (which throws without a key). Web push stays dormant until
/// the key is pasted into `push_config.dart`.
PushService createPushService(ApiClient api) =>
    _WebPushService(DeviceRegistrar(api, platform: 'web'));

class _WebPushService implements PushService {
  _WebPushService(this._registrar);

  final DeviceRegistrar _registrar;

  String? _token;
  StreamSubscription<String>? _refreshSub;
  bool _warnedNoKey = false;

  @override
  Future<void> registerForUser(String uid, {bool prompt = true}) async {
    if (kWebPushVapidKey.isEmpty) {
      if (!_warnedNoKey) {
        _warnedNoKey = true;
        logger.info(
          'Web push dormant: kWebPushVapidKey is empty. Paste the Web Push '
          'certificate key into push_config.dart to enable it.',
        );
      }
      return;
    }

    final messaging = FirebaseMessaging.instance;
    final settings = prompt
        ? await messaging.requestPermission()
        : await messaging.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.denied ||
        settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      logger.info('Push permission not granted; skipping device registration');
      return;
    }

    final token = await messaging.getToken(vapidKey: kWebPushVapidKey);
    _token = token;
    await _registrar.register(token);

    _refreshSub ??= messaging.onTokenRefresh.listen((newToken) {
      _token = newToken;
      unawaited(_registrar.register(newToken));
    });
  }

  @override
  Future<void> unregister() async {
    await _refreshSub?.cancel();
    _refreshSub = null;
    if (kWebPushVapidKey.isEmpty) return;
    // Recover the token when the in-memory copy was lost (a reopened tab with a
    // restored session that never re-registered this run). Without this, signing
    // out leaves the old token registered and a shared device keeps getting the
    // previous user's pushes. Mirrors the Android impl.
    final token = _token ??
        await FirebaseMessaging.instance.getToken(vapidKey: kWebPushVapidKey);
    await _registrar.unregister(token);
    _token = null;
  }
}
