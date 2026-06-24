import 'package:dio/dio.dart';

/// Attaches the Firebase ID token as a Bearer `Authorization` header when one is
/// available. Feature-agnostic: it depends only on a token-fetch callback, so
/// `core/network` never imports the auth feature. Register AFTER
/// `ConnectivityInterceptor` so offline requests are rejected before a token is
/// fetched.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._idToken);

  final Future<String?> Function() _idToken;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final String? token = await _idToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
