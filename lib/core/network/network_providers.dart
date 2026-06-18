import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../connectivity/connectivity_providers.dart';
import 'api_client.dart';
import 'api_config.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/connectivity_interceptor.dart';

/// Seam: returns the current user's Firebase ID token (or null when signed out).
/// Defaults to null so `core/network` has no compile-time dependency on the auth
/// feature. `bootstrap()` overrides this to read `authRepositoryProvider`.
final authTokenProvider = Provider<Future<String?> Function()>(
  (ref) => () async => null,
);

final dioProvider = Provider<Dio>((ref) {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: kApiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  // Order matters: reject-offline first, then attach the token.
  dio.interceptors.add(
    ConnectivityInterceptor(ref.watch(connectivityServiceProvider)),
  );
  dio.interceptors.add(AuthInterceptor(ref.watch(authTokenProvider)));
  ref.onDispose(() => dio.close(force: true));
  return dio;
});

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(dioProvider)),
);
