import 'sync_scheduler.dart';

SyncScheduler createSyncScheduler(
  Future<void> Function() onFlush, {
  required bool enableBackground,
  void Function()? backgroundEntryPoint,
}) =>
    throw UnsupportedError('No sync scheduler for this platform');
