import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:agape_logos_game/features/dictionary/data/dictionary_remote.dart';
import 'package:agape_logos_game/features/dictionary/data/dictionary_repository_impl.dart';
import 'package:agape_logos_game/features/dictionary/domain/dictionary_entry.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

DictionaryEntry _entry(String word, {String? definition, String tier = 'easy'}) =>
    DictionaryEntry(word: word, definition: definition, tier: tier, level: null);

class _FakeRemote implements DictionaryRemote {
  _FakeRemote({this.result = const [], this.throwOffline = false});
  List<DictionaryEntry> result;
  bool throwOffline;
  int calls = 0;

  @override
  Future<List<DictionaryEntry>> dictionary() async {
    calls++;
    if (throwOffline) {
      throw DioException(
        requestOptions: RequestOptions(path: '/me/dictionary'),
        type: DioExceptionType.connectionError,
      );
    }
    return result;
  }
}

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('online: fetches GET /me/dictionary and writes through to the cache',
      () async {
    final remote = _FakeRemote(result: [
      _entry('CAB', definition: 'a taxi', tier: 'easy'),
      _entry('ZIP', definition: 'fasten', tier: 'medium'),
    ]);
    final repo = DictionaryRepositoryImpl(db, remote);

    final entries = await repo.fetch('u1');

    expect(remote.calls, 1);
    expect(entries.map((e) => e.word), ['CAB', 'ZIP']);
    final cached = await db.dictionaryEntriesDao.all('u1');
    expect(cached.map((r) => r.word), ['CAB', 'ZIP']); // sorted by word
  });

  test('offline: serves the cached dictionary for the same uid', () async {
    final remote = _FakeRemote(result: [_entry('ABC', definition: 'alphabet')]);
    final repo = DictionaryRepositoryImpl(db, remote);
    await repo.fetch('u1'); // seed the cache

    remote.throwOffline = true;
    final entries = await repo.fetch('u1');
    expect(entries.map((e) => e.word), ['ABC']);
    expect(entries.first.definition, 'alphabet');
  });

  test('offline with no cache returns an empty list (never throws)', () async {
    final repo = DictionaryRepositoryImpl(db, _FakeRemote(throwOffline: true));
    expect(await repo.fetch('u1'), isEmpty);
  });

  test('offline never leaks another account\'s cached dictionary', () async {
    final repo1 =
        DictionaryRepositoryImpl(db, _FakeRemote(result: [_entry('ONE')]));
    await repo1.fetch('u1');

    final repo2 = DictionaryRepositoryImpl(db, _FakeRemote(throwOffline: true));
    expect(await repo2.fetch('u2'), isEmpty);
  });

  test('watch streams cached entries for the uid', () async {
    final repo =
        DictionaryRepositoryImpl(db, _FakeRemote(result: [_entry('WORD')]));
    await repo.fetch('u1');
    final streamed = await repo.watch('u1').first;
    expect(streamed.map((e) => e.word), ['WORD']);
  });
}
