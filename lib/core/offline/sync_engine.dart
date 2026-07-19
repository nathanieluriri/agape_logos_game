import '../connectivity/connectivity_service.dart';
import '../logging/app_logger.dart';
import '../storage/app_database.dart';

/// Result of attempting to send one queued mutation to the server.
enum SendOutcome { success, transient, permanent }

/// Sends a queued mutation to the server. Injected so tests need no network.
///
/// May either return a [SendOutcome] or throw (e.g. a Dio/Socket exception).
/// A thrown error is treated as [SendOutcome.transient] by the engine.
typedef MutationSender = Future<SendOutcome> Function(PendingMutation row);

/// Invoked after a mutation is confirmed synced, keyed by `mutation.kind`.
/// Lets features reconcile server truth without `core/offline` importing them.
typedef MutationReconciler = Future<void> Function(PendingMutation row);

/// Drains the offline mutation queue with single-flight, exponential backoff,
/// an atomic in-flight claim, and a feature-agnostic reconciliation seam.
class SyncEngine {
  SyncEngine({
    required this._db,
    required this._connectivity,
    required this._sender,
    this._reconcilers = const {},
    int Function()? clock,
    this._maxRetries = 10,
  }) : _clock = clock ?? _wallClock;

  /// Ceiling for the exponential backoff between attempts. Combined with the
  /// foreground heartbeat/resume triggers, a transient failure keeps retrying
  /// at most every 30s while the app is open instead of backing off past the
  /// session.
  static const int _maxBackoffMs = 30000;

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
    // Claim the guard BEFORE the first await so two calls scheduled close
    // together cannot both pass the check while still suspended.
    if (_flushing) return;
    _flushing = true;
    try {
      if (!await _connectivity.isOnline) return;
      final List<PendingMutation> due = await _db.pendingMutationsDao.due(_clock());
      for (final PendingMutation row in due) {
        try {
          await _process(row);
        } catch (e, s) {
          // One bad row must never abort draining the rest of the batch.
          logger.warning('Mutation ${row.id} processing error', e, s);
        }
      }
    } finally {
      _flushing = false;
    }
  }

  Future<void> _process(PendingMutation row) async {
    // Atomically claim the row so an overlapping flush (e.g. a WorkManager
    // background isolate running while the app is open) cannot double-send it.
    final int claimed = await _db.pendingMutationsDao.claim(row.id);
    if (claimed == 0) return; // already claimed/handled elsewhere

    SendOutcome outcome;
    try {
      outcome = await _sender(row);
    } catch (_) {
      // A thrown error (Dio/Socket) is the common transient case.
      outcome = SendOutcome.transient;
    }

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
          // Exponential backoff with a clamped exponent (avoids shift overflow,
          // incl. the 32-bit web int model), capped so retries never drift
          // beyond a session-friendly interval.
          final int shift = (next - 1).clamp(0, 30);
          int delayMs = 1000 * (1 << shift);
          if (delayMs > _maxBackoffMs) delayMs = _maxBackoffMs;
          await _db.pendingMutationsDao.scheduleRetry(row.id, next, _clock() + delayMs);
        }
      case SendOutcome.permanent:
        logger.warning('Mutation ${row.id} failed permanently');
        await _db.pendingMutationsDao.markFailed(row.id, 'permanent failure');
    }
  }
}
