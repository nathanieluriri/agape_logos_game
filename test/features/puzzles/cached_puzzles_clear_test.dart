import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agape_logos_game/core/storage/app_database.dart';

void main() {
  // Bumped 9 -> 10 by the powerup tutorial (adds powerupTutorialSeen).
  test('schemaVersion is 10', () {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    expect(db.schemaVersion, 10);
    addTearDown(db.close);
  });

  test('clearAll removes every cached puzzle', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.cachedPuzzlesDao.insertAll([
      CachedPuzzlesCompanion.insert(
        puzzleId: 'ACT', tier: 'easy', tierRank: 0, rackSize: 3,
        lettersJson: '["A","C","T"]', anchor: 'CAT',
        answersJson: '[]', answerCount: 0, orderIndex: 0, assignedAt: 0,
      ),
    ]);
    expect(await db.cachedPuzzlesDao.unplayedCount(), 1);
    await db.cachedPuzzlesDao.clearAll();
    expect(await db.cachedPuzzlesDao.unplayedCount(), 0);
  });
}
