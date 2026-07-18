import 'package:agape_logos_game/core/network/api_client.dart';
import 'package:agape_logos_game/features/multiplayer/application/server_clock.dart';
import 'package:agape_logos_game/features/multiplayer/data/match_remote.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _CapturingDio extends Fake implements Dio {
  final List<({String path, Object? data, Map<String, dynamic>? headers})> calls = [];
  Map<String, dynamic> next = const {};
  int? throwStatus;
  // Issue #58: an artificial round trip, so a test can prove the client
  // measures real request latency and folds it into the clock sync rather
  // than assuming the response landed instantly.
  Duration delay = Duration.zero;

  @override
  Future<Response<T>> request<T>(String path,
      {Object? data, Map<String, dynamic>? queryParameters, Options? options,
      CancelToken? cancelToken,
      ProgressCallback? onSendProgress, ProgressCallback? onReceiveProgress}) async {
    calls.add((path: path, data: data, headers: options?.headers));
    if (delay > Duration.zero) await Future<void>.delayed(delay);
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

  test('powerup returns ok:false on 402 (none owned)', () async {
    final dio = _CapturingDio()..throwStatus = 402;
    final remote = HttpMatchRemote(ApiClient(dio));
    final result = await remote.powerup('m1', 'fog_bank', eventId: 'e1');
    expect(result.ok, isFalse);
    expect(result.reason, 'not_owned');
  });

  test('powerup surfaces a "blocked" reason from the response body', () async {
    final dio = _CapturingDio()..next = {'ok': true, 'reason': 'blocked'};
    final remote = HttpMatchRemote(ApiClient(dio));
    final result = await remote.powerup('m1', 'fog_bank', eventId: 'e1');
    expect(result.ok, isTrue);
    expect(result.reason, 'blocked');
  });

  // Issue #58: settle() must measure the request's actual round trip and
  // feed it to ServerClock.sync, rather than syncing as if the response
  // arrived instantly. With a 120ms artificial round trip and a serverNow
  // captured right before the call fires, an UNCORRECTED sync would land
  // the offset around -120ms (deviceNow has moved on by the delay before
  // the response is read); the half-RTT correction should measurably pull
  // that back up, landing well above a raw, uncorrected reading.
  test('settle measures the round trip and half-RTT-corrects the synced clock',
      () async {
    final dio = _CapturingDio()..delay = const Duration(milliseconds: 120);
    final clock = ServerClock();
    final remote = HttpMatchRemote(ApiClient(dio), clock: clock);
    final serverNowMs = DateTime.now().millisecondsSinceEpoch;
    dio.next = {'serverNow': serverNowMs};

    await remote.settle('m1');

    expect(clock.isSynced, isTrue);
    // Uncorrected, the offset would sit near -120ms; the correction should
    // keep it comfortably above -90ms even allowing for test scheduling
    // jitter (serverNow is captured before the call fires, so the setup gap
    // sits outside the measured round trip).
    expect(clock.offset.inMilliseconds, greaterThan(-90));
  });

  test('powerup also round-trip-corrects the synced clock', () async {
    final dio = _CapturingDio()..delay = const Duration(milliseconds: 120);
    final clock = ServerClock();
    final remote = HttpMatchRemote(ApiClient(dio), clock: clock);
    final serverNowMs = DateTime.now().millisecondsSinceEpoch;
    dio.next = {'ok': true, 'serverNow': serverNowMs};

    await remote.powerup('m1', 'fog_bank', eventId: 'e1');

    expect(clock.isSynced, isTrue);
    expect(clock.offset.inMilliseconds, greaterThan(-90));
  });
}
