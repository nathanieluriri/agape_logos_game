import 'package:agape_logos_game/core/network/api_client.dart';
import 'package:agape_logos_game/features/multiplayer/data/match_remote.dart';
import 'package:agape_logos_game/features/multiplayer/domain/challenge_outcome.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _CapturingDio extends Fake implements Dio {
  final List<({String path, Object? data, Map<String, dynamic>? headers})> calls = [];
  Map<String, dynamic> next = const {};
  int? throwStatus;
  bool connectionError = false;

  @override
  Future<Response<T>> request<T>(String path,
      {Object? data, Map<String, dynamic>? queryParameters, Options? options,
      CancelToken? cancelToken,
      ProgressCallback? onSendProgress, ProgressCallback? onReceiveProgress}) async {
    calls.add((path: path, data: data, headers: options?.headers));
    if (connectionError) {
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
  test('challenge posts toUid + settings.mode + idempotency key, returns ChallengeSent', () async {
    final dio = _CapturingDio()..next = {'matchId': 'm1'};
    final remote = HttpMatchRemote(ApiClient(dio));
    final out = await remote.challenge('uid1', mode: 'live');
    expect(out, isA<ChallengeSent>());
    expect((out as ChallengeSent).matchId, 'm1');
    expect(dio.calls.single.path, '/matches/challenge');
    final body = dio.calls.single.data as Map;
    expect(body['toUid'], 'uid1');
    expect((body['settings'] as Map)['mode'], 'live');
    expect(dio.calls.single.headers!['idempotency-key'], isNotEmpty);
  });

  test('challenge maps 409 to ChallengeAlreadyOpen', () async {
    final dio = _CapturingDio()..throwStatus = 409;
    final remote = HttpMatchRemote(ApiClient(dio));
    final out = await remote.challenge('uid1', mode: 'async');
    expect(out, isA<ChallengeAlreadyOpen>());
  });

  test('challenge maps 404 to ChallengeNotFriends', () async {
    final dio = _CapturingDio()..throwStatus = 404;
    final remote = HttpMatchRemote(ApiClient(dio));
    final out = await remote.challenge('uid1', mode: 'async');
    expect(out, isA<ChallengeNotFriends>());
  });

  test('challenge maps a connection error to ChallengeUnavailable', () async {
    final dio = _CapturingDio()..connectionError = true;
    final remote = HttpMatchRemote(ApiClient(dio));
    final out = await remote.challenge('uid1', mode: 'live');
    expect(out, isA<ChallengeUnavailable>());
  });
}
