import '../core/offline/sync_engine.dart';
import '../core/storage/app_database.dart';
import '../features/level_results/data/level_result_repository_impl.dart';
import '../features/multiplayer/domain/multiplayer_config.dart';
import '../features/puzzles/puzzles_config.dart';

/// Single source of truth for the per-`kind` reconcilers, shared by the
/// foreground bootstrap and the background WorkManager isolate.
///
/// INVARIANT: every reconciler MUST be idempotent. `claim()` does not confer
/// exclusive cross-isolate ownership (it re-claims `inFlight` rows for crash
/// recovery), so under background sync a mutation's success path can run more
/// than once. Both handlers below are idempotent (an UPDATE and a DELETE), and
/// [onPuzzleResultSynced] must be too (a refetch/merge is).
///
/// [onPuzzleResultSynced] closes the reconciliation loop for the wallet: the
/// server mints coins when a puzzle result syncs, so after each confirmed
/// result the foreground passes a `GET /me` refetch here. That pulls the
/// authoritative balance/level into the cache the moment they exist:
/// within the session, not on the next app restart. The background isolate
/// passes nothing (no Riverpod there); the pending-delta-aware merge on the
/// next foreground fetch reconciles instead.
///
/// [onMatchLeaveSynced] closes the same loop for a durably-queued forfeit
/// (issue #38): once the leave actually reaches the server (which finalizes the
/// match), the foreground refreshes the Resume list / badge / history so a
/// forfeit that only synced after the player came back online still drops the
/// match without a manual pull-to-refresh. The background isolate passes
/// nothing (no UI there); the invalidation is a no-op it does not need.
Map<String, MutationReconciler> buildMutationReconcilers(
  AppDatabase db, {
  Future<void> Function()? onPuzzleResultSynced,
  Future<void> Function()? onMatchLeaveSynced,
}) =>
    <String, MutationReconciler>{
      kLevelResultKind: (row) =>
          db.levelResultsDao.markSynced(row.idempotencyKey),
      kPuzzleResultKind: (row) async {
        await db.cachedPuzzlesDao.deleteByPuzzleId(row.idempotencyKey);
        if (onPuzzleResultSynced != null) await onPuzzleResultSynced();
      },
      // A forfeit needs no local cleanup (there is no local match cache to
      // touch); the reconciler exists only to refresh the resume surfaces once
      // the server has finalized. Idempotent: a refresh is safe to run twice.
      kMatchLeaveKind: (row) async {
        if (onMatchLeaveSynced != null) await onMatchLeaveSynced();
      },
    };
