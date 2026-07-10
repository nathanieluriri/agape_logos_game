import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  DictionaryEntriesCompanion entry(
    String uid,
    String word, {
    String? definition,
    String tier = 'easy',
    int? level,
    int foundAt = 0,
  }) =>
      DictionaryEntriesCompanion.insert(
        uid: uid,
        word: word,
        definition: Value(definition),
        tier: tier,
        level: Value(level),
        foundAt: foundAt,
      );

  test('replaceAll writes rows and watch(uid) reads them back sorted by word',
      () async {
    await db.dictionaryEntriesDao.replaceAll('u1', [
      entry('u1', 'ZIP', definition: 'fasten', tier: 'medium'),
      entry('u1', 'ABC', definition: null, tier: 'easy'),
    ]);
    final rows = await db.dictionaryEntriesDao.watch('u1').first;
    expect(rows.map((r) => r.word), ['ABC', 'ZIP']);
    expect(rows.first.definition, isNull);
    expect(rows.last.definition, 'fasten');
  });

  test('replaceAll is a full replace for the uid (removes words gone from the '
      'server), leaving other accounts untouched', () async {
    await db.dictionaryEntriesDao.replaceAll('u1', [
      entry('u1', 'CAB', definition: 'a taxi'),
      entry('u1', 'OLD', definition: 'to be dropped'),
    ]);
    await db.dictionaryEntriesDao.replaceAll('u2', [entry('u2', 'ZED')]);

    // A later fetch for u1 no longer includes OLD.
    await db.dictionaryEntriesDao
        .replaceAll('u1', [entry('u1', 'CAB', definition: 'a taxi')]);

    expect((await db.dictionaryEntriesDao.all('u1')).map((r) => r.word), ['CAB']);
    // u2 is unaffected by u1 replaces.
    expect((await db.dictionaryEntriesDao.all('u2')).map((r) => r.word), ['ZED']);
  });

  test('watch(uid) never leaks another account\'s words', () async {
    await db.dictionaryEntriesDao.replaceAll('u1', [entry('u1', 'ONE')]);
    await db.dictionaryEntriesDao.replaceAll('u2', [entry('u2', 'TWO')]);
    expect((await db.dictionaryEntriesDao.watch('u1').first).map((r) => r.word),
        ['ONE']);
  });

  test('clear drops all dictionary rows', () async {
    await db.dictionaryEntriesDao.replaceAll('u1', [entry('u1', 'ONE')]);
    await db.dictionaryEntriesDao.clear();
    expect(await db.dictionaryEntriesDao.all('u1'), isEmpty);
  });
}
