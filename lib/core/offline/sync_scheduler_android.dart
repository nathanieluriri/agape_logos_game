import 'dart:async';
import 'dart:io' show Platform;

import 'package:workmanager/workmanager.dart';

import '../connectivity/connectivity_service.dart';
import '../storage/app_database.dart';
import 'sync_engine.dart';
import 'sync_scheduler.dart';

/// Unique name of the periodic WorkManager flush task.
const String kFlushTask = 'agape.flushQueue';

/// WorkManager background entry point. Runs in a FRESH isolate with no Riverpod
/// scope, so it constructs its own database + engine. Replace the placeholder
/// sender with the real backend sender when one exists.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != kFlushTask) return true;
    final AppDatabase db = AppDatabase();
    try {
      final SyncEngine engine = SyncEngine(
        db: db,
        connectivity: ConnectivityService(),
        // TODO: inject the real backend sender once it exists. Transient keeps
        // queued mutations pending (never lost) until then.
        sender: (row) async => SendOutcome.transient,
      );
      await engine.flush();
    } finally {
      await db.close();
    }
    return true;
  });
}

SyncScheduler createSyncScheduler(
  Future<void> Function() onFlush, {
  required bool enableBackground,
}) =>
    AndroidSyncScheduler(onFlush, enableBackground: enableBackground);

/// Android gets true background flushing via WorkManager, plus the same
/// foreground safety net so the queue also drains while the app is open.
/// (On non-Android `dart:io` platforms only the foreground net is active.)
class AndroidSyncScheduler implements SyncScheduler {
  AndroidSyncScheduler(
    this._onFlush, {
    ConnectivityService? connectivity,
    bool enableBackground = false,
  })  : _connectivity = connectivity ?? ConnectivityService(),
        _enableBackground = enableBackground;

  final Future<void> Function() _onFlush;
  final ConnectivityService _connectivity;
  final bool _enableBackground;
  StreamSubscription<bool>? _sub;

  @override
  Future<void> initialize() async {
    _sub = _connectivity.onStatusChange.listen((bool online) {
      if (online) _onFlush();
    });
    // Background flushing stays off until 2c wires the real isolate sender; the
    // placeholder isolate sender returns transient, which would burn retries and
    // mark good mutations failed after ~5 background cycles.
    if (_enableBackground && Platform.isAndroid) {
      await Workmanager().initialize(callbackDispatcher);
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
