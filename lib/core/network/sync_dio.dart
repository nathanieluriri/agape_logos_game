import 'package:dio/dio.dart';

import '../connectivity/connectivity_service.dart';
import 'api_config.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/connectivity_interceptor.dart';

/// Builds the Dio used for backend sync, Riverpod-free so it is reusable in the
/// WorkManager background isolate (which has no provider scope). Interceptor
/// order is load-bearing: reject-offline first, then attach the token.
Dio buildSyncDio({
  required ConnectivityService connectivity,
  required Future<String?> Function() idToken,
}) {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: kApiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  dio.interceptors.add(ConnectivityInterceptor(connectivity));
  dio.interceptors.add(AuthInterceptor(idToken));
  return dio;
}
