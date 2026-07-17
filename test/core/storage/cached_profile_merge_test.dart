import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

CachedProfileCompanion _server(
  String uid, {
  int highestLevel = 0,
  int totalScore = 0,
  int coins = 0,
  String displayName = 'Player',
}) =>
    CachedProfileCompanion.insert(
      id: const Value(0),
      uid: uid,
      displayName: displayName,
      avatarId: 'avatar_01',
      locale: 'en',
      soundEnabled: true,
      musicEnabled: true,
      highestLevel: highestLevel,
      totalScore: totalScore,
      coins: Value(coins),
      createdAt: 1000,
      updatedAt: 2000,
    );

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('first write seeds the row', () async {
    await db.cachedProfileDao.mergeServerProfile(_server('u1', highestLevel: 3));
    expect((await db.cachedProfileDao.read('u1'))?.highestLevel, 3);
  });

  test('server behind local does NOT regress highestLevel (the bug)', () async {
    await db.cachedProfileDao.mergeServerProfile(_server('u1', highestLevel: 5));
    // A stale GET /me arrives with an older level; local win not yet synced.
    await db.cachedProfileDao
        .mergeServerProfile(_server('u1', highestLevel: 4, coins: 200));
    final row = await db.cachedProfileDao.read('u1');
    expect(row?.highestLevel, 5); // preserved
    expect(row?.coins, 200); // server-owned column still follows the server
  });

  test('server ahead of local advances highestLevel (cross-device)', () async {
    await db.cachedProfileDao.mergeServerProfile(_server('u1', highestLevel: 2));
    await db.cachedProfileDao.mergeServerProfile(_server('u1', highestLevel: 7));
    expect((await db.cachedProfileDao.read('u1'))?.highestLevel, 7);
  });

  test('totalScore is also monotonic (max), coins follows server', () async {
    await db.cachedProfileDao
        .mergeServerProfile(_server('u1', totalScore: 900, coins: 50));
    await db.cachedProfileDao
        .mergeServerProfile(_server('u1', totalScore: 800, coins: 30));
    final row = await db.cachedProfileDao.read('u1');
    expect(row?.totalScore, 900); // preserved
    expect(row?.coins, 30); // server wins for coins (can go down via purchase)
  });

  test('different uid replaces the whole row (account switch)', () async {
    await db.cachedProfileDao.mergeServerProfile(_server('u1', highestLevel: 9));
    await db.cachedProfileDao.mergeServerProfile(_server('u2', highestLevel: 1));
    expect(await db.cachedProfileDao.read('u1'), isNull);
    expect((await db.cachedProfileDao.read('u2'))?.highestLevel, 1);
  });
}
