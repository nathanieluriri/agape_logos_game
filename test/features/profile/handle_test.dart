import 'package:agape_logos_game/core/network/api_client.dart';
import 'package:agape_logos_game/features/profile/data/profile_remote.dart';
import 'package:agape_logos_game/features/profile/domain/handle_outcome.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _CapturingDio extends Fake implements Dio {
  final List<({String path, Object? data, Map<String, dynamic>? headers})> calls = [];
  Map<String, dynamic> next = const {};
  int? throwStatus;
  bool throwConnectionError = false;

  @override
  Future<Response<T>> request<T>(String path,
      {Object? data, Map<String, dynamic>? queryParameters, Options? options,
      CancelToken? cancelToken,
      ProgressCallback? onSendProgress, ProgressCallback? onReceiveProgress}) async {
    calls.add((path: path, data: data, headers: options?.headers));
    if (throwConnectionError) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        type: DioExceptionType.connectionError,
      );
    }
    if (throwStatus != null) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        response: Response(
          requestOptions: RequestOptions(path: path),
          statusCode: throwStatus,
        ),
      );
    }
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: next as T,
      statusCode: 200,
    );
  }
}

void main() {
  test('200 returns HandleChanged carrying the returned handle', () async {
    final dio = _CapturingDio()..next = {'handle': 'nat_word'};
    final remote = HttpProfileRemote(ApiClient(dio));
    final out = await remote.setHandle('nat_word', idempotencyKey: 'k1');
    expect(out, isA<HandleChanged>());
    expect((out as HandleChanged).handle, 'nat_word');
  });

  test('409 returns HandleTaken', () async {
    final dio = _CapturingDio()..throwStatus = 409;
    final remote = HttpProfileRemote(ApiClient(dio));
    final out = await remote.setHandle('nat_word', idempotencyKey: 'k1');
    expect(out, isA<HandleTaken>());
  });

  test('400 returns HandleInvalid', () async {
    final dio = _CapturingDio()..throwStatus = 400;
    final remote = HttpProfileRemote(ApiClient(dio));
    final out = await remote.setHandle('bad handle', idempotencyKey: 'k1');
    expect(out, isA<HandleInvalid>());
  });

  test('connection error returns HandleUnavailable', () async {
    final dio = _CapturingDio()..throwConnectionError = true;
    final remote = HttpProfileRemote(ApiClient(dio));
    final out = await remote.setHandle('nat_word', idempotencyKey: 'k1');
    expect(out, isA<HandleUnavailable>());
  });

  test('other status code returns HandleUnavailable', () async {
    final dio = _CapturingDio()..throwStatus = 500;
    final remote = HttpProfileRemote(ApiClient(dio));
    final out = await remote.setHandle('nat_word', idempotencyKey: 'k1');
    expect(out, isA<HandleUnavailable>());
  });

  test('PUTs to /me/handle with body and idempotency-key header', () async {
    final dio = _CapturingDio()..next = {'handle': 'nat_word'};
    final remote = HttpProfileRemote(ApiClient(dio));
    await remote.setHandle('nat_word', idempotencyKey: 'k1');
    expect(dio.calls.single.path, '/me/handle');
    expect((dio.calls.single.data as Map)['handle'], 'nat_word');
    expect(dio.calls.single.headers!['idempotency-key'], 'k1');
  });
}
