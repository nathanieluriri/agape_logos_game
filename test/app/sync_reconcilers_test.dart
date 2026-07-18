import 'package:agape_logos_game/app/sync_reconcilers.dart';
import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:agape_logos_game/features/level_results/data/level_result_repository_impl.dart';
import 'package:agape_logos_game/features/multiplayer/domain/multiplayer_config.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

PendingMutation _row(String idempotencyKey) => PendingMutation(
      id: 'm1',
      endpoint: '/levels/1/result',
      method: 'POST',
      payloadJson: '{}',
      idempotencyKey: idempotencyKey,
      kind: kLevelResultKind,
      createdAt: 0,
      retryCount: 0,
      nextAttemptAt: 0,
      status: 'inFlight',
    );

PendingMutation _leaveRow() => const PendingMutation(
      id: 'm2',
      endpoint: '/matches/m1/leave',
      method: 'POST',
      payloadJson: '{}',
      idempotencyKey: 'leave:m1',
      kind: kMatchLeaveKind,
      createdAt: 0,
      retryCount: 0,
      nextAttemptAt: 0,
      status: 'inFlight',
    );

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('the level_result reconciler flips the cached row synced flag', () async {
    await db.levelResultsDao.upsert(
      LevelResultsCompanion.insert(
        id: 'r1',
        levelId: 1,
        score: 10,
        completedAt: 0,
      ),
    );

    final reconcilers = buildMutationReconcilers(db);
    await reconcilers[kLevelResultKind]!(_row('r1'));

    final row = await db.select(db.levelResults).getSingle();
    expect(row.synced, isTrue);
  });

  test('the match_leave reconciler runs the refresh callback idempotently',
      () async {
    var refreshes = 0;
    final reconcilers = buildMutationReconcilers(
      db,
      onMatchLeaveSynced: () async => refreshes++,
    );

    // Running the same forfeit reconciler twice (background sync can re-run a
    // success path) just refreshes twice; a refresh is safe to repeat.
    await reconcilers[kMatchLeaveKind]!(_leaveRow());
    await reconcilers[kMatchLeaveKind]!(_leaveRow());

    expect(refreshes, 2);
  });

  test('the match_leave reconciler is a safe no-op with no callback (background)',
      () async {
    // The background isolate builds reconcilers with no callbacks; the forfeit
    // reconciler must complete without touching Riverpod or throwing.
    final reconcilers = buildMutationReconcilers(db);
    await reconcilers[kMatchLeaveKind]!(_leaveRow());
  });
}
