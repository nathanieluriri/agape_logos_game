import 'package:agape_logos_game/core/connectivity/connectivity_service.dart';
import 'package:agape_logos_game/core/network/api_config.dart';
import 'package:agape_logos_game/core/network/interceptors/auth_interceptor.dart';
import 'package:agape_logos_game/core/network/interceptors/connectivity_interceptor.dart';
import 'package:agape_logos_game/core/network/sync_dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildSyncDio sets the base URL and the interceptor order', () {
    final dio = buildSyncDio(
      connectivity: ConnectivityService(),
      idToken: () async => null,
    );
    addTearDown(() => dio.close());

    expect(dio.options.baseUrl, kApiBaseUrl);
    // A fresh Dio already carries an internal ImplyContentTypeInterceptor, so
    // assert RELATIVE order (not absolute index): reject-offline BEFORE attaching
    // a token. indexWhere ordering pins the load-bearing order; a presence-only
    // check would pass even if the two were swapped.
    final int connIdx =
        dio.interceptors.indexWhere((i) => i is ConnectivityInterceptor);
    final int authIdx =
        dio.interceptors.indexWhere((i) => i is AuthInterceptor);
    expect(connIdx, isNonNegative, reason: 'ConnectivityInterceptor present');
    expect(authIdx, isNonNegative, reason: 'AuthInterceptor present');
    expect(connIdx, lessThan(authIdx));
  });
}
