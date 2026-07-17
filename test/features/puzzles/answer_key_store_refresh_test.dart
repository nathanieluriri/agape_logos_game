import 'package:agape_logos_game/core/network/api_client.dart';
import 'package:agape_logos_game/features/puzzles/data/answer_key_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeApi implements ApiClient {
  _FakeApi(this._keys);
  final List<String?> _keys; // one value returned per call
  int calls = 0;
  @override
  Future<Response<T>> request<T>(String path,
      {String method = 'GET', Object? data, Map<String, String>? headers}) async {
    final key = _keys[calls.clamp(0, _keys.length - 1)];
    calls++;
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: {'key': key} as T,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // In-memory secure storage for tests.
  // PLAN: FlutterSecureStorage.setMockInitialValues is the plugin's test
  // surface; if the running plugin version exposes it differently, inject a
  // fake via the constructor's `storage:` param instead.
  FlutterSecureStorage.setMockInitialValues({});

  test('refresh drops the cached key and re-fetches from the server', () async {
    // First key, then a rotated key on the second (refresh) call.
    final api = _FakeApi(['AAAA', 'BBBB']);
    final store = AnswerKeyStore(api);

    final first = await store.keyFor('u1');
    expect(api.calls, 1);
    // Second keyFor is served from memo (no new call).
    await store.keyFor('u1');
    expect(api.calls, 1);

    final refreshed = await store.refresh('u1');
    expect(api.calls, 2); // forced a new GET
    expect(refreshed, isNot(first));
  });
}
