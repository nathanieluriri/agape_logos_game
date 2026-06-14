import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> upsert(String id, {required int completedAt}) {
    return db.levelResultsDao.upsert(
      LevelResultsCompanion.insert(
        id: id,
        levelId: 1,
        score: 0,
        completedAt: completedAt,
      ),
    );
  }

  test('watchAll orders by completedAt descending', () async {
    await upsert('old', completedAt: 1);
    await upsert('new', completedAt: 3);
    await upsert('mid', completedAt: 2);

    final rows = await db.levelResultsDao.watchAll().first;
    expect(rows.map((r) => r.id).toList(), ['new', 'mid', 'old']);
  });

  test('markSynced flips synced on exactly the targeted row', () async {
    await upsert('a', completedAt: 1);
    await upsert('b', completedAt: 2);

    await db.levelResultsDao.markSynced('a');

    final rows = await db.levelResultsDao.watchAll().first;
    expect(rows.firstWhere((r) => r.id == 'a').synced, isTrue);
    expect(rows.firstWhere((r) => r.id == 'b').synced, isFalse);
  });
}
