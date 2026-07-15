import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/handle_outcome.dart';
import '../domain/profile.dart';

/// Thin transport for the profile endpoint. `GET /me` is authed; the ID token
/// is attached by the Dio interceptor (see `core/network`), so no auth handling
/// is needed here.
abstract class ProfileRemote {
  Future<Profile> me();

  /// `GET /me/coins` - the wallet balance only, for screens that do not need the
  /// full profile payload.
  Future<int> coins();

  /// `PUT /me/handle` {handle} -> {handle}. Online, server-authoritative: the
  /// server can reject the claim (409 taken, 400 invalid), so the result is a
  /// [HandleOutcome] rather than a thrown exception.
  Future<HandleOutcome> setHandle(
    String handle, {
    required String idempotencyKey,
  });
}

class HttpProfileRemote implements ProfileRemote {
  HttpProfileRemote(this._api);

  final ApiClient _api;

  @override
  Future<Profile> me() async {
    final res = await _api.request<Map<String, dynamic>>('/me', method: 'GET');
    return Profile.fromJson(res.data ?? const {});
  }

  @override
  Future<int> coins() async {
    final res = await _api.request<Map<String, dynamic>>(
      '/me/coins',
      method: 'GET',
    );
    return (res.data?['coins'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<HandleOutcome> setHandle(
    String handle, {
    required String idempotencyKey,
  }) async {
    try {
      final res = await _api.request<Map<String, dynamic>>(
        '/me/handle',
        method: 'PUT',
        data: <String, String>{'handle': handle},
        headers: <String, String>{'idempotency-key': idempotencyKey},
      );
      final returned = res.data?['handle'] as String?;
      return HandleChanged(returned ?? handle);
    } on DioException catch (e) {
      switch (e.response?.statusCode) {
        case 409:
          return const HandleTaken();
        case 400:
          return const HandleInvalid();
        default:
          return const HandleUnavailable();
      }
    }
  }
}
