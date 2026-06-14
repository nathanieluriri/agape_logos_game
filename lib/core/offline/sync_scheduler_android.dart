import 'dart:async';
import 'dart:io' show Platform;

import 'package:workmanager/workmanager.dart';

import '../connectivity/connectivity_service.dart';
import 'sync_scheduler.dart';

/// Unique name of the periodic WorkManager flush task. The top-level callback
/// dispatcher (registered in bootstrap) keys off this name.
const String kFlushTask = 'agape.flushQueue';

SyncScheduler createSyncScheduler(Future<void> Function() onFlush) =>
    AndroidSyncScheduler(onFlush);

/// Android gets true background flushing via WorkManager, plus the same
/// foreground safety net so the queue also drains while the app is open.
/// (On non-Android `dart:io` platforms only the foreground net is active.)
class AndroidSyncScheduler implements SyncScheduler {
  AndroidSyncScheduler(this._onFlush, {ConnectivityService? connectivity})
      : _connectivity = connectivity ?? ConnectivityService();

  final Future<void> Function() _onFlush;
  final ConnectivityService _connectivity;
  StreamSubscription<bool>? _sub;

  @override
  Future<void> initialize() async {
    _sub = _connectivity.onStatusChange.listen((bool online) {
      if (online) _onFlush();
    });
    if (Platform.isAndroid) {
      await Workmanager().registerPeriodicTask(
        kFlushTask,
        kFlushTask,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(networkType: NetworkType.connected),
      );
    }
    await _onFlush();
  }

  @override
  Future<void> requestFlush() => _onFlush();

  Future<void> dispose() async => _sub?.cancel();
}
