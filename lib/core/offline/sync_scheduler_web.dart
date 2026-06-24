import 'dart:async';

import '../connectivity/connectivity_service.dart';
import 'sync_scheduler.dart';

SyncScheduler createSyncScheduler(
  Future<void> Function() onFlush, {
  required bool enableBackground,
  void Function()? backgroundEntryPoint,
}) =>
    // Web has no OS background sync; the flags are accepted for a uniform factory
    // signature and intentionally ignored.
    ForegroundSyncScheduler(onFlush);

/// Web flushes only while a tab is alive: on reachability-return and on demand.
/// There is no true OS background sync in the browser.
class ForegroundSyncScheduler implements SyncScheduler {
  ForegroundSyncScheduler(this._onFlush, {ConnectivityService? connectivity})
      : _connectivity = connectivity ?? ConnectivityService();

  final Future<void> Function() _onFlush;
  final ConnectivityService _connectivity;
  StreamSubscription<bool>? _sub;

  @override
  Future<void> initialize() async {
    _sub = _connectivity.onStatusChange.listen((bool online) {
      if (online) _onFlush();
    });
    await _onFlush();
  }

  @override
  Future<void> requestFlush() => _onFlush();

  @override
  Future<void> dispose() async => _sub?.cancel();
}
