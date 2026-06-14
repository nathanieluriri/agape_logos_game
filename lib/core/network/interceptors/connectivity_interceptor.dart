import 'package:dio/dio.dart';

import '../../connectivity/connectivity_service.dart';

/// Short-circuits requests when offline so the app never fires a request while
/// disconnected. Repositories route reads to cache / writes to the queue.
class ConnectivityInterceptor extends Interceptor {
  ConnectivityInterceptor(this._connectivity);

  final ConnectivityService _connectivity;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!await _connectivity.isOnline) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: 'offline',
        ),
      );
      return;
    }
    handler.next(options);
  }
}
