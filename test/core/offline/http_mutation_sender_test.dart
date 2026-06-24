import 'package:agape_logos_game/core/network/api_client.dart';
import 'package:agape_logos_game/core/offline/http_mutation_sender.dart';
import 'package:agape_logos_game/core/offline/sync_engine.dart';
import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:agape_logos_game/features/auth/domain/auth_repository.dart';
import 'package:agape_logos_game/features/auth/domain/auth_user.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

class _MockAuthRepository extends Mock implements AuthRepository {}

PendingMutation _row({String endpoint = '/levels/1/result'}) => PendingMutation(
      id: 'm1',
      endpoint: endpoint,
      method: 'POST',
      payloadJson: '{"id":"r1","levelId":1,"score":10,"completedAt":0}',
      idempotencyKey: 'r1',
      kind: 'level_result',
      createdAt: 0,
      retryCount: 0,
      nextAttemptAt: 0,
      status: 'pending',
    );

Response<dynamic> _resp(int code) =>
    Response<dynamic>(requestOptions: RequestOptions(path: '/x'), statusCode: code);

DioException _dioWith(int code) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      response: _resp(code),
      type: DioExceptionType.badResponse,
    );

DioException _dioNoResponse() => DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.connectionError,
    );

void main() {
  late _MockApiClient api;
  late _MockAuthRepository auth;
  late HttpMutationSender sender;

  const signedIn = AuthUser(uid: 'u1');

  void stubRequest({int? returns, Object? throws}) {
    final call = when(
      () => api.request<dynamic>(
        any(),
        method: any(named: 'method'),
        data: any(named: 'data'),
        headers: any(named: 'headers'),
      ),
    );
    if (throws != null) {
      call.thenThrow(throws);
    } else {
      call.thenAnswer((_) async => _resp(returns!));
    }
  }

  setUp(() {
    api = _MockApiClient();
    auth = _MockAuthRepository();
    sender = HttpMutationSender(api: api, auth: auth);
    when(() => auth.currentUser).thenReturn(signedIn);
  });

  test('signed out short-circuits to transient without calling the API', () async {
    when(() => auth.currentUser).thenReturn(null);

    expect(await sender.send(_row()), SendOutcome.transient);
    verifyNever(
      () => api.request<dynamic>(any(),
          method: any(named: 'method'),
          data: any(named: 'data'),
          headers: any(named: 'headers')),
    );
  });

  test('200 maps to success and passes the idempotency-key header and decoded payload',
      () async {
    stubRequest(returns: 200);

    expect(await sender.send(_row()), SendOutcome.success);

    final captured = verify(
      () => api.request<dynamic>(
        captureAny(),
        method: captureAny(named: 'method'),
        data: captureAny(named: 'data'),
        headers: captureAny(named: 'headers'),
      ),
    ).captured;
    expect(captured[0], '/levels/1/result');
    expect(captured[1], 'POST');
    expect(captured[2], <String, dynamic>{
      'id': 'r1',
      'levelId': 1,
      'score': 10,
      'completedAt': 0,
    });
    expect((captured[3] as Map)['idempotency-key'], 'r1');
  });

  test('401 maps to transient', () async {
    stubRequest(returns: 401);
    expect(await sender.send(_row()), SendOutcome.transient);
  });

  test('403 maps to transient', () async {
    stubRequest(returns: 403);
    expect(await sender.send(_row()), SendOutcome.transient);
  });

  test('408 maps to transient', () async {
    stubRequest(returns: 408);
    expect(await sender.send(_row()), SendOutcome.transient);
  });

  test('429 maps to transient', () async {
    stubRequest(returns: 429);
    expect(await sender.send(_row()), SendOutcome.transient);
  });

  test('400 maps to permanent', () async {
    stubRequest(returns: 400);
    expect(await sender.send(_row()), SendOutcome.permanent);
  });

  test('404 maps to permanent', () async {
    stubRequest(returns: 404);
    expect(await sender.send(_row()), SendOutcome.permanent);
  });

  test('500 maps to transient', () async {
    stubRequest(returns: 500);
    expect(await sender.send(_row()), SendOutcome.transient);
  });

  test('503 maps to transient', () async {
    stubRequest(returns: 503);
    expect(await sender.send(_row()), SendOutcome.transient);
  });

  test('DioException with a 400 response maps to permanent', () async {
    stubRequest(throws: _dioWith(400));
    expect(await sender.send(_row()), SendOutcome.permanent);
  });

  test('DioException with no response maps to transient', () async {
    stubRequest(throws: _dioNoResponse());
    expect(await sender.send(_row()), SendOutcome.transient);
  });
}
