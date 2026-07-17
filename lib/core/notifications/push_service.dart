import 'package:uuid/uuid.dart';

import '../network/api_client.dart';
// Selects the platform-appropriate push implementation at compile time, exactly
// like `core/storage/connection/connection.dart`: the Android/native impl calls
// `getToken()`; the web impl calls `getToken(vapidKey: kWebPushVapidKey)` and
// no-ops when the key is empty.
import 'push_service_io.dart'
    if (dart.library.js_interop) 'push_service_web.dart' as impl;

/// Client side of FCM push registration for friend-request notifications.
abstract interface class PushService {
  /// Ensures a token exists for the signed-in user and registers it with the
  /// backend. No-op if permission is denied or, on web, if the VAPID key is not
  /// configured.
  ///
  /// [prompt] controls the lazy-permission rule: the Friends page calls with
  /// `prompt: true` (the first deliberate ask, when the user opts into the
  /// social feature); `bootstrap`'s sign-in call uses `prompt: false` so a
  /// restored session at cold start only registers a token when permission was
  /// ALREADY granted, and never shows a dialog on launch.
  Future<void> registerForUser(String uid, {bool prompt = true});

  /// Deletes the current device token from the backend and locally. Called on
  /// sign-out so a shared device stops receiving the previous user's pushes.
  Future<void> unregister();
}

/// Builds the platform-appropriate [PushService].
PushService createPushService(ApiClient api) => impl.createPushService(api);

/// The testable seam: talks to the backend device registry over [ApiClient],
/// with `FirebaseMessaging` kept out entirely. Both platform impls delegate
/// their transport here, so the register/unregister wire contract is unit-tested
/// against a mocked Dio without needing a real platform to mint a token.
class DeviceRegistrar {
  DeviceRegistrar(this._api, {required this.platform, Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final ApiClient _api;

  /// `'android'` or `'web'`.
  final String platform;

  final Uuid _uuid;

  /// POSTs `{token, platform}` to `/me/devices` with a fresh idempotency key.
  /// No-op when [token] is null (permission denied, or web with no VAPID key).
  /// Network failures are swallowed: a missed registration must never crash or
  /// block the caller.
  Future<void> register(String? token) async {
    if (token == null || token.isEmpty) return;
    try {
      await _api.request<Map<String, dynamic>>(
        '/me/devices',
        method: 'POST',
        data: <String, String>{'token': token, 'platform': platform},
        headers: <String, String>{'idempotency-key': _uuid.v4()},
      );
    } catch (_) {
      // Best-effort: the token is re-sent on the next sign-in / onTokenRefresh.
    }
  }

  /// DELETEs `/me/devices/{token}`. No-op when there is no token.
  Future<void> unregister(String? token) async {
    if (token == null || token.isEmpty) return;
    try {
      await _api.request<Map<String, dynamic>>(
        '/me/devices/$token',
        method: 'DELETE',
      );
    } catch (_) {
      // Best-effort.
    }
  }
}
