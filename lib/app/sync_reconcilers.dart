import '../core/offline/sync_engine.dart';
import '../core/storage/app_database.dart';
import '../features/level_results/data/level_result_repository_impl.dart';
import '../features/puzzles/puzzles_config.dart';

/// Single source of truth for the per-`kind` reconcilers, shared by the
/// foreground bootstrap and the background WorkManager isolate.
///
/// INVARIANT: every reconciler MUST be idempotent. `claim()` does not confer
/// exclusive cross-isolate ownership (it re-claims `inFlight` rows for crash
/// recovery), so under background sync a mutation's success path can run more
/// than once. Both handlers below are idempotent (an UPDATE and a DELETE).
Map<String, MutationReconciler> buildMutationReconcilers(AppDatabase db) =>
    <String, MutationReconciler>{
      kLevelResultKind: (row) =>
          db.levelResultsDao.markSynced(row.idempotencyKey),
      kPuzzleResultKind: (row) =>
          db.cachedPuzzlesDao.deleteByPuzzleId(row.idempotencyKey),
    };
