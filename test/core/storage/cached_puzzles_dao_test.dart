import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  CachedPuzzlesCompanion row(
    String id, {
    required String tier,
    required int tierRank,
    required int orderIndex,
    bool completed = false,
  }) =>
      CachedPuzzlesCompanion.insert(
        puzzleId: id,
        tier: tier,
        tierRank: tierRank,
        rackSize: id.length,
        lettersJson: '[]',
        anchor: id,
        answersJson: '[]',
        answerCount: 0,
        orderIndex: orderIndex,
        assignedAt: 0,
        completed: Value(completed),
      );

  test('insertAll is insert-or-ignore on puzzleId', () async {
    await db.cachedPuzzlesDao.insertAll([row('NOW', tier: 'easy', tierRank: 0, orderIndex: 0)]);
    await db.cachedPuzzlesDao.insertAll([row('NOW', tier: 'easy', tierRank: 0, orderIndex: 9)]);
    expect(await db.cachedPuzzlesDao.unplayedCount(), 1);
  });

  test('nextOrderIndex is max+1, 0 when empty', () async {
    expect(await db.cachedPuzzlesDao.nextOrderIndex(), 0);
    await db.cachedPuzzlesDao.insertAll([row('A', tier: 'easy', tierRank: 0, orderIndex: 5)]);
    expect(await db.cachedPuzzlesDao.nextOrderIndex(), 6);
  });

  test('currentPuzzle orders by tierRank then orderIndex, skipping completed', () async {
    await db.cachedPuzzlesDao.insertAll([
      row('HARD1', tier: 'hard', tierRank: 2, orderIndex: 0),
      row('EASY2', tier: 'easy', tierRank: 0, orderIndex: 2),
      row('EASY1', tier: 'easy', tierRank: 0, orderIndex: 1, completed: true),
      row('MED1', tier: 'medium', tierRank: 1, orderIndex: 0),
    ]);
    final current = await db.cachedPuzzlesDao.currentPuzzle();
    expect(current!.puzzleId, 'EASY2'); // EASY1 completed -> skipped; easy before medium/hard
  });

  test('remainingByTier counts only unplayed', () async {
    await db.cachedPuzzlesDao.insertAll([
      row('E1', tier: 'easy', tierRank: 0, orderIndex: 0),
      row('E2', tier: 'easy', tierRank: 0, orderIndex: 1, completed: true),
      row('M1', tier: 'medium', tierRank: 1, orderIndex: 0),
    ]);
    expect(await db.cachedPuzzlesDao.remainingByTier(), {'easy': 1, 'medium': 1});
  });

  test('markCompleted then deleteByPuzzleId', () async {
    await db.cachedPuzzlesDao.insertAll([row('X', tier: 'easy', tierRank: 0, orderIndex: 0)]);
    await db.cachedPuzzlesDao.markCompleted('X');
    expect(await db.cachedPuzzlesDao.unplayedCount(), 0);
    await db.cachedPuzzlesDao.deleteByPuzzleId('X');
    final all = await db.select(db.cachedPuzzles).get();
    expect(all, isEmpty);
  });
}
