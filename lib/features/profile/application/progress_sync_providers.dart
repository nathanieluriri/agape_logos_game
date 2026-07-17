import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/offline/offline_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../../puzzles/puzzles_config.dart';

/// True when at least one `puzzle_result` mutation has permanently failed to
/// sync (retries exhausted). This is the ONLY signal we surface about sync
/// internals: everything else stays invisible. When true, a completed level
/// will never reach the cloud, so it is at risk of being lost on reinstall.
final progressSyncFailedProvider = StreamProvider<bool>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.pendingMutationsDao
      .watchFailed(kPuzzleResultKind)
      .map((rows) => rows.isNotEmpty);
});

/// Re-arms failed progress mutations and kicks a flush. Called by the notice's
/// Retry button.
// PLAN: the plan sketched this taking a `Ref`, but the only call site is a
// ConsumerWidget passing a `WidgetRef` (not assignable to `Ref` in Riverpod 3),
// so the param is `WidgetRef`. Adjust if a non-widget caller appears.
Future<void> retryFailedProgress(WidgetRef ref) async {
  final db = ref.read(appDatabaseProvider);
  await db.pendingMutationsDao.resetFailed(kPuzzleResultKind);
  await ref.read(syncEngineProvider).flush();
}
