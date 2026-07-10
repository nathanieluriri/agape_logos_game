import 'package:agape_logos_game/core/network/api_client.dart';
import 'package:agape_logos_game/features/multiplayer/data/match_remote.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _CapturingDio extends Fake implements Dio {
  final List<({String path, Object? data, Map<String, dynamic>? headers})> calls = [];
  Map<String, dynamic> next = const {};
  int? throwStatus;

  @override
  Future<Response<T>> request<T>(String path,
      {Object? data, Map<String, dynamic>? queryParameters, Options? options,
      CancelToken? cancelToken,
      ProgressCallback? onSendProgress, ProgressCallback? onReceiveProgress}) async {
    calls.add((path: path, data: data, headers: options?.headers));
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
  test('create posts settings + an idempotency key, returns id + code', () async {
    final dio = _CapturingDio()..next = {'matchId': 'm1', 'code': 'ABCD'};
    final remote = HttpMatchRemote(ApiClient(dio));
    final out = await remote.create({'difficulty': 'easy'});
    expect(out.matchId, 'm1');
    expect(out.code, 'ABCD');
    expect(dio.calls.single.path, '/matches');
    expect((dio.calls.single.data as Map)['settings'], {'difficulty': 'easy'});
    expect(dio.calls.single.headers!['idempotency-key'], isNotEmpty);
  });

  test('submit keys idempotency on the normalized word', () async {
    final dio = _CapturingDio()..next = {};
    final remote = HttpMatchRemote(ApiClient(dio));
    await remote.submit('m1', 'tear');
    expect(dio.calls.single.headers!['idempotency-key'], 'submit:m1:TEAR');
    expect((dio.calls.single.data as Map)['word'], 'TEAR');
  });

  test('powerup returns false on 402 (none owned)', () async {
    final dio = _CapturingDio()..throwStatus = 402;
    final remote = HttpMatchRemote(ApiClient(dio));
    expect(await remote.powerup('m1', 'fog_bank', eventId: 'e1'), isFalse);
  });
}
