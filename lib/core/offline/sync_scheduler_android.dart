import 'dart:async';
import 'dart:io' show Platform;

import 'package:workmanager/workmanager.dart';

import '../connectivity/connectivity_service.dart';
import 'sync_scheduler.dart';

/// Unique name of the periodic WorkManager flush task.
const String kFlushTask = 'agape.flushQueue';

SyncScheduler createSyncScheduler(
  Future<void> Function() onFlush, {
  required bool enableBackground,
  void Function()? backgroundEntryPoint,
}) =>
    AndroidSyncScheduler(
      onFlush,
      enableBackground: enableBackground,
      backgroundEntryPoint: backgroundEntryPoint,
    );

/// Android gets true background flushing via WorkManager, plus the same
/// foreground safety net so the queue also drains while the app is open.
/// (On non-Android `dart:io` platforms only the foreground net is active.)
class AndroidSyncScheduler implements SyncScheduler {
  AndroidSyncScheduler(
    this._onFlush, {
    ConnectivityService? connectivity,
    this._enableBackground = false,
    this._backgroundEntryPoint,
  }) : _connectivity = connectivity ?? ConnectivityService();

  final Future<void> Function() _onFlush;
  final ConnectivityService _connectivity;
  final bool _enableBackground;
  final void Function()? _backgroundEntryPoint;
  StreamSubscription<bool>? _sub;

  @override
  Future<void> initialize() async {
    _sub = _connectivity.onStatusChange.listen((bool online) {
      if (online) _onFlush();
    });
    if (_enableBackground && Platform.isAndroid) {
      assert(
        _backgroundEntryPoint != null,
        'enableBackground requires a backgroundEntryPoint',
      );
      await Workmanager().initialize(_backgroundEntryPoint!);
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

  @override
  Future<void> dispose() async => _sub?.cancel();
}
