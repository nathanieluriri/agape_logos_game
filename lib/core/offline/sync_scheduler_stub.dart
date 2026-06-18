import 'sync_scheduler.dart';

SyncScheduler createSyncScheduler(
  Future<void> Function() onFlush, {
  required bool enableBackground,
}) =>
    throw UnsupportedError('No sync scheduler for this platform');
