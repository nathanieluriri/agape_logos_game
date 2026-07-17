import '../../../core/network/api_client.dart';
import '../domain/dictionary_entry.dart';

/// Thin transport for `GET /me/dictionary`. The ID token is attached by the Dio
/// interceptor (see `core/network`), so no auth handling is needed here.
abstract class DictionaryRemote {
  Future<List<DictionaryEntry>> dictionary();
}

class HttpDictionaryRemote implements DictionaryRemote {
  HttpDictionaryRemote(this._api);

  final ApiClient _api;

  @override
  Future<List<DictionaryEntry>> dictionary() async {
    final res = await _api.request<Map<String, dynamic>>(
      '/me/dictionary',
      method: 'GET',
    );
    final list = (res.data?['entries'] as List<dynamic>?) ?? const <dynamic>[];
    return list
        .map((e) => DictionaryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
