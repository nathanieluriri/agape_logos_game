import 'package:agape_logos_game/core/network/api_client.dart';
import 'package:agape_logos_game/core/notifications/push_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Captures the transport calls the [DeviceRegistrar] makes so the registration
/// logic can be proven without ever touching `FirebaseMessaging.instance` (which
/// needs a real platform).
class _CapturingDio extends Fake implements Dio {
  final List<({String path, String? method, Object? data, Map<String, dynamic>? headers})> calls = [];
  bool throwConnectionError = false;

  @override
  Future<Response<T>> request<T>(String path,
      {Object? data, Map<String, dynamic>? queryParameters, Options? options,
      CancelToken? cancelToken,
      ProgressCallback? onSendProgress, ProgressCallback? onReceiveProgress}) async {
    calls.add((path: path, method: options?.method, data: data, headers: options?.headers));
    if (throwConnectionError) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        type: DioExceptionType.connectionError,
      );
    }
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: const <String, dynamic>{} as T,
      statusCode: 200,
    );
  }
}

void main() {
  group('DeviceRegistrar.register', () {
    test('POSTs {token, platform} to /me/devices with an idempotency-key', () async {
      final dio = _CapturingDio();
      final registrar = DeviceRegistrar(ApiClient(dio), platform: 'android');

      await registrar.register('tok-123');

      expect(dio.calls, hasLength(1));
      final call = dio.calls.single;
      expect(call.path, '/me/devices');
      expect(call.method, 'POST');
      expect((call.data as Map)['token'], 'tok-123');
      expect((call.data as Map)['platform'], 'android');
      expect(call.headers!['idempotency-key'], isNotEmpty);
    });

    test('is a no-op when the token is null (permission denied / no VAPID key)', () async {
      final dio = _CapturingDio();
      final registrar = DeviceRegistrar(ApiClient(dio), platform: 'web');

      await registrar.register(null);

      expect(dio.calls, isEmpty);
    });

    test('swallows a connection error so a failed register never crashes the app', () async {
      final dio = _CapturingDio()..throwConnectionError = true;
      final registrar = DeviceRegistrar(ApiClient(dio), platform: 'android');

      await expectLater(registrar.register('tok-123'), completes);
    });
  });

  group('DeviceRegistrar.unregister', () {
    test('DELETEs /me/devices/{token}', () async {
      final dio = _CapturingDio();
      final registrar = DeviceRegistrar(ApiClient(dio), platform: 'android');

      await registrar.unregister('tok-123');

      expect(dio.calls, hasLength(1));
      final call = dio.calls.single;
      expect(call.path, '/me/devices/tok-123');
      expect(call.method, 'DELETE');
    });

    test('is a no-op when there is no token', () async {
      final dio = _CapturingDio();
      final registrar = DeviceRegistrar(ApiClient(dio), platform: 'android');

      await registrar.unregister(null);

      expect(dio.calls, isEmpty);
    });
  });
}
