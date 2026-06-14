import 'sync_scheduler.dart';

SyncScheduler createSyncScheduler(Future<void> Function() onFlush) =>
    throw UnsupportedError('No sync scheduler for this platform');
