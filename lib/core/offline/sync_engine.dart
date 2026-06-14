import '../connectivity/connectivity_service.dart';
import '../logging/app_logger.dart';
import '../storage/app_database.dart';

/// Result of attempting to send one queued mutation to the server.
enum SendOutcome { success, transient, permanent }

/// Sends a queued mutation to the server. Injected so tests need no network.
typedef MutationSender = Future<SendOutcome> Function(PendingMutation row);

/// Invoked after a mutation is confirmed synced, keyed by `mutation.kind`.
/// Lets features reconcile server truth without `core/offline` importing them.
typedef MutationReconciler = Future<void> Function(PendingMutation row);

/// Drains the offline mutation queue with single-flight, exponential backoff,
/// and a feature-agnostic reconciliation seam.
class SyncEngine {
  SyncEngine({
    required AppDatabase db,
    required ConnectivityService connectivity,
    required MutationSender sender,
    Map<String, MutationReconciler> reconcilers = const {},
    int Function()? clock,
    int maxRetries = 5,
  })  : _db = db,
        _connectivity = connectivity,
        _sender = sender,
        _reconcilers = reconcilers,
        _clock = clock ?? _wallClock,
        _maxRetries = maxRetries;

  final AppDatabase _db;
  final ConnectivityService _connectivity;
  final MutationSender _sender;
  final Map<String, MutationReconciler> _reconcilers;
  final int Function() _clock;
  final int _maxRetries;

  bool _flushing = false;

  static int _wallClock() => DateTime.now().millisecondsSinceEpoch;

  /// Drains all due mutations. Single-flight: a concurrent call is a no-op.
  Future<void> flush() async {
    if (_flushing) return;
    if (!await _connectivity.isOnline) return;
    _flushing = true;
    try {
      final List<PendingMutation> due = await _db.pendingMutationsDao.due(_clock());
      for (final PendingMutation row in due) {
        await _process(row);
      }
    } finally {
      _flushing = false;
    }
  }

  Future<void> _process(PendingMutation row) async {
    final SendOutcome outcome = await _sender(row);
    switch (outcome) {
      case SendOutcome.success:
        await _db.pendingMutationsDao.markSynced(row.id);
        final MutationReconciler? reconcile = _reconcilers[row.kind];
        if (reconcile != null) await reconcile(row);
      case SendOutcome.transient:
        final int next = row.retryCount + 1;
        if (next > _maxRetries) {
          await _db.pendingMutationsDao.markFailed(row.id, 'max retries exceeded');
        } else {
          final int delayMs = 1000 * (1 << (next - 1)); // exponential backoff
          await _db.pendingMutationsDao.scheduleRetry(row.id, next, _clock() + delayMs);
        }
      case SendOutcome.permanent:
        logger.warning('Mutation ${row.id} failed permanently');
        await _db.pendingMutationsDao.markFailed(row.id, 'permanent failure');
    }
  }
}
