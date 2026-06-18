import 'dart:typed_data';

import 'package:agape_logos_game/core/network/interceptors/auth_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Captures the outgoing request so we can assert the headers the interceptor
/// set, and returns a canned 200 so the request completes.
class _CaptureAdapter implements HttpClientAdapter {
  RequestOptions? captured;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured = options;
    return ResponseBody.fromString(
      '{}',
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioWith(AuthInterceptor interceptor, _CaptureAdapter adapter) {
  final Dio dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
  dio.httpClientAdapter = adapter;
  dio.interceptors.add(interceptor);
  return dio;
}

void main() {
  test('sets the Authorization header when a token is present', () async {
    final adapter = _CaptureAdapter();
    final dio = _dioWith(AuthInterceptor(() async => 'tok123'), adapter);

    await dio.get<dynamic>('/x');

    expect(adapter.captured!.headers['Authorization'], 'Bearer tok123');
  });

  test('omits the Authorization header when the token is null', () async {
    final adapter = _CaptureAdapter();
    final dio = _dioWith(AuthInterceptor(() async => null), adapter);

    await dio.get<dynamic>('/x');

    expect(adapter.captured!.headers.containsKey('Authorization'), isFalse);
  });
}
