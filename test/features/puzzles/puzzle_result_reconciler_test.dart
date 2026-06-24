import 'package:agape_logos_game/app/sync_reconcilers.dart';
import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:agape_logos_game/features/puzzles/puzzles_config.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

PendingMutation _row(String idempotencyKey) => PendingMutation(
      id: 'm1',
      endpoint: '/puzzles/$idempotencyKey/result',
      method: 'POST',
      payloadJson: '{}',
      idempotencyKey: idempotencyKey,
      kind: kPuzzleResultKind,
      createdAt: 0,
      retryCount: 0,
      nextAttemptAt: 0,
      status: 'inFlight',
    );

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('puzzle_result reconciler deletes the cached row by puzzleId', () async {
    await db.cachedPuzzlesDao.insertAll([
      CachedPuzzlesCompanion.insert(
        puzzleId: 'NOW', tier: 'easy', tierRank: 0, rackSize: 3,
        lettersJson: '[]', anchor: 'NOW', answersJson: '[]', answerCount: 0,
        orderIndex: 0, assignedAt: 0,
      ),
    ]);

    final reconcilers = buildMutationReconcilers(db);
    await reconcilers[kPuzzleResultKind]!(_row('NOW'));

    final all = await db.select(db.cachedPuzzles).get();
    expect(all, isEmpty);
  });

  test('reconciler is idempotent on a missing row', () async {
    final reconcilers = buildMutationReconcilers(db);
    await reconcilers[kPuzzleResultKind]!(_row('GONE')); // must not throw
  });
}
