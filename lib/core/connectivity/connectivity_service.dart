import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// Real reachability (actual internet access, not just "an interface exists").
///
/// This is the single choke point for "are we online?". The Dio interceptor
/// and repositories consult it so the offline rule lives in one place.
class ConnectivityService {
  ConnectivityService({InternetConnection? checker})
      : _checker = checker ?? InternetConnection();

  final InternetConnection _checker;

  /// Emits `true` when reachable, `false` otherwise.
  Stream<bool> get onStatusChange => _checker.onStatusChange
      .map((InternetStatus s) => s == InternetStatus.connected);

  /// One-shot reachability check.
  Future<bool> get isOnline => _checker.hasInternetAccess;
}
