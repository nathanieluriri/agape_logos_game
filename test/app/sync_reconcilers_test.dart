import 'package:agape_logos_game/app/sync_reconcilers.dart';
import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:agape_logos_game/features/level_results/data/level_result_repository_impl.dart';
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
}
