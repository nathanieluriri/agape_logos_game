import '../../../core/network/api_client.dart';
import '../domain/profile.dart';

/// Thin transport for the profile endpoint. `GET /me` is authed; the ID token
/// is attached by the Dio interceptor (see `core/network`), so no auth handling
/// is needed here.
abstract class ProfileRemote {
  Future<Profile> me();

  /// `GET /me/coins` - the wallet balance only, for screens that do not need the
  /// full profile payload.
  Future<int> coins();
}

class HttpProfileRemote implements ProfileRemote {
  HttpProfileRemote(this._api);

  final ApiClient _api;

  @override
  Future<Profile> me() async {
    final res = await _api.request<Map<String, dynamic>>(
      '/me',
      method: 'GET',
    );
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
}
