import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('watch emits defaults (all on) when nothing has been set', () async {
    final row = await db.gameSettingsDao.watch().first;
    expect(row.soundEffects, isTrue);
    expect(row.music, isTrue);
    expect(row.notifications, isTrue);
    expect(row.haptics, isTrue);
  });

  test('each setter flips exactly its own field', () async {
    await db.gameSettingsDao.setSoundEffects(false);
    await db.gameSettingsDao.setNotifications(false);

    final row = await db.gameSettingsDao.watch().first;
    expect(row.soundEffects, isFalse);
    expect(row.notifications, isFalse);
    expect(row.music, isTrue);
    expect(row.haptics, isTrue);
  });

  test('clearLocalGameData wipes progress but keeps settings', () async {
    await db.gameSettingsDao.setMusic(false);
    await db.levelResultsDao.upsert(
      LevelResultsCompanion.insert(id: 'x', levelId: 1, score: 0, completedAt: 1),
    );

    await db.clearLocalGameData();

    expect(await db.levelResultsDao.watchAll().first, isEmpty);
    final row = await db.gameSettingsDao.watch().first;
    expect(row.music, isFalse);
  });
}
