import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../network/api_config.dart';

/// Real reachability (actual internet access, not just "an interface exists").
///
/// We probe our own backend `/health` endpoint rather than the package's
/// default third-party captive-portal URLs (Apple, Cloudflare, Google). On Web
/// those defaults are cross-origin and blocked by CORS, so the check always
/// resolves to "offline" and strands the player on an empty pond even with a
/// perfect connection. Our `/health` sends the right CORS headers, so the probe
/// works on Web and Android alike. It also makes "online" mean the one thing
/// this app actually cares about: our backend is reachable.
///
/// This is the single choke point for "are we online?". The Dio interceptor
/// and repositories consult it so the offline rule lives in one place. (The
/// probe itself uses the `http` package, not Dio, so it never loops back
/// through the connectivity interceptor.)
class ConnectivityService {
  ConnectivityService({InternetConnection? checker})
      : _checker = checker ?? _backendChecker();

  final InternetConnection _checker;

  /// A checker that probes only our backend `/health` endpoint. The package
  /// issues a `HEAD` request and treats HTTP 200 as reachable;
  /// `useDefaultOptions: false` drops the captive-portal URLs entirely.
  static InternetConnection _backendChecker() =>
      InternetConnection.createInstance(
        useDefaultOptions: false,
        customCheckOptions: [
          InternetCheckOption(uri: Uri.parse('$kApiBaseUrl/health')),
        ],
      );

  /// Emits `true` when reachable, `false` otherwise.
  Stream<bool> get onStatusChange => _checker.onStatusChange
      .map((InternetStatus s) => s == InternetStatus.connected);

  /// One-shot reachability check.
  Future<bool> get isOnline => _checker.hasInternetAccess;
}
