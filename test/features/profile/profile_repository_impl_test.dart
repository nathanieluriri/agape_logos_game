import 'dart:convert';

import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:agape_logos_game/features/profile/data/profile_repository_impl.dart';
import 'package:agape_logos_game/features/profile/data/profile_remote.dart';
import 'package:agape_logos_game/features/profile/domain/profile.dart';
import 'package:agape_logos_game/features/profile/profile_config.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Profile _profile(String uid, {int totalScore = 0, int coins = 0}) => Profile(
      uid: uid,
      displayName: 'Player',
      avatarId: 'avatar_01',
      locale: 'en',
      soundEnabled: true,
      musicEnabled: true,
      highestLevel: 0,
      totalScore: totalScore,
      coins: coins,
      createdAt: 1000,
      updatedAt: 2000,
    );

class _FakeRemote implements ProfileRemote {
  _FakeRemote({this.result, this.throwOffline = false});
  Profile? result;
  bool throwOffline;
  int meCalls = 0;
  int coinsCalls = 0;

  @override
  Future<Profile> me() async {
    meCalls++;
    if (throwOffline) {
      throw DioException(
        requestOptions: RequestOptions(path: '/me'),
        type: DioExceptionType.connectionError,
      );
    }
    return result!;
  }

  @override
  Future<int> coins() async {
    coinsCalls++;
    if (throwOffline) {
      throw DioException(
        requestOptions: RequestOptions(path: '/me/coins'),
        type: DioExceptionType.connectionError,
      );
    }
    return result?.coins ?? 0;
  }
}

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('online: fetches GET /me and writes through to the cache', () async {
    final remote = _FakeRemote(result: _profile('u1', totalScore: 42));
    final repo = ProfileRepositoryImpl(db, remote);

    final profile = await repo.fetch('u1');

    expect(remote.meCalls, 1);
    expect(profile?.totalScore, 42);
    final cached = await db.cachedProfileDao.read('u1');
    expect(cached?.totalScore, 42);
  });

  test('fetchCoins online writes the balance through to the cached row',
      () async {
    final remote = _FakeRemote(result: _profile('u1', coins: 250));
    final repo = ProfileRepositoryImpl(db, remote);
    await repo.fetch('u1'); // seed the cached row (coins 250)

    // Server balance moved on; the coin-only read updates just the balance.
    remote.result = _profile('u1', coins: 400);
    final coins = await repo.fetchCoins('u1');

    expect(coins, 400);
    expect(remote.coinsCalls, 1);
    final cached = await db.cachedProfileDao.read('u1');
    expect(cached?.coins, 400);
  });

  test('fetchCoins offline serves the cached balance', () async {
    final remote = _FakeRemote(result: _profile('u1', coins: 99));
    final repo = ProfileRepositoryImpl(db, remote);
    await repo.fetch('u1');

    remote.throwOffline = true;
    expect(await repo.fetchCoins('u1'), 99);
  });

  test('addCoinsLocally bumps the cached balance optimistically', () async {
    final remote = _FakeRemote(result: _profile('u1', coins: 10));
    final repo = ProfileRepositoryImpl(db, remote);
    await repo.fetch('u1');

    await repo.addCoinsLocally('u1', 15);

    final cached = await db.cachedProfileDao.read('u1');
    expect(cached?.coins, 25);
  });

  test('advanceLevelLocally raises highestLevel but never lowers it', () async {
    final remote = _FakeRemote(result: _profile('u1'));
    final repo = ProfileRepositoryImpl(db, remote);
    await repo.fetch('u1'); // highestLevel 0

    await repo.advanceLevelLocally('u1', 3);
    expect((await db.cachedProfileDao.read('u1'))?.highestLevel, 3);

    // A stale lower level must not regress the cached value.
    await repo.advanceLevelLocally('u1', 2);
    expect((await db.cachedProfileDao.read('u1'))?.highestLevel, 3);
  });

  test('offline: serves the cached profile for the same uid', () async {
    // Prime the cache with an online fetch, then go offline.
    final remote = _FakeRemote(result: _profile('u1', totalScore: 7));
    final repo = ProfileRepositoryImpl(db, remote);
    await repo.fetch('u1');

    remote.throwOffline = true;
    final profile = await repo.fetch('u1');

    expect(profile?.totalScore, 7); // served from cache
  });

  test('offline with no cache returns null', () async {
    final repo = ProfileRepositoryImpl(db, _FakeRemote(throwOffline: true));

    expect(await repo.fetch('u1'), isNull);
  });

  test('offline never leaks another account\'s cached profile', () async {
    // Cache belongs to u1.
    final repo = ProfileRepositoryImpl(
      db,
      _FakeRemote(result: _profile('u1')),
    );
    await repo.fetch('u1');

    // A different user (u2) is offline: must not see u1's row.
    final repo2 = ProfileRepositoryImpl(db, _FakeRemote(throwOffline: true));
    expect(await repo2.fetch('u2'), isNull);
  });

  test('clear drops the cached profile', () async {
    final repo = ProfileRepositoryImpl(db, _FakeRemote(result: _profile('u1')));
    await repo.fetch('u1');

    await repo.clear();

    expect(await db.cachedProfileDao.read('u1'), isNull);
  });

  test('updateDisplayName applies optimistically and enqueues a PUT /me job',
      () async {
    final repo = ProfileRepositoryImpl(db, _FakeRemote(result: _profile('u1')));
    await repo.fetch('u1'); // seed the cache with the default 'Player'

    await repo.updateDisplayName('u1', 'Grace Hopper');

    // Optimistic local update is visible immediately.
    final cached = await db.cachedProfileDao.read('u1');
    expect(cached?.displayName, 'Grace Hopper');

    // A PUT /me job is enqueued for the sync engine.
    final due = await db.pendingMutationsDao.due(1 << 40);
    expect(due, hasLength(1));
    expect(due.single.endpoint, '/me');
    expect(due.single.method, 'PUT');
    expect(due.single.kind, kProfileDisplayNameKind);
    expect(due.single.idempotencyKey, 'profile-name-u1');
    expect(
      jsonDecode(due.single.payloadJson),
      <String, String>{'displayName': 'Grace Hopper'},
    );
  });

  test('fetch does not regress highestLevel when the server is behind an '
      'unsynced local win (the offline reopen bug)', () async {
    final remote = _FakeRemote(result: _profile('u1'));
    final repo = ProfileRepositoryImpl(db, remote);
    await repo.fetch('u1'); // seed row, highestLevel 0

    // Player wins level 1 offline: local advance to 1 (server still 0).
    await repo.advanceLevelLocally('u1', 1);
    expect((await db.cachedProfileDao.read('u1'))?.highestLevel, 1);

    // Reopen online: GET /me still returns highestLevel 0 (win not synced).
    remote.result = _profile('u1'); // highestLevel 0
    await repo.fetch('u1');

    // The locally-advanced level must be preserved, not clobbered.
    expect((await db.cachedProfileDao.read('u1'))?.highestLevel, 1);
  });

  test('fetch adopts a higher server level (progress made on another device)',
      () async {
    final remote = _FakeRemote(result: _profile('u1'));
    final repo = ProfileRepositoryImpl(db, remote);
    await repo.fetch('u1');
    await repo.advanceLevelLocally('u1', 2);

    remote.result = const Profile(
      uid: 'u1', displayName: 'Player', avatarId: 'avatar_01', locale: 'en',
      soundEnabled: true, musicEnabled: true, highestLevel: 6, totalScore: 0,
      coins: 0, createdAt: 1000, updatedAt: 2000,
    );
    await repo.fetch('u1');
    expect((await db.cachedProfileDao.read('u1'))?.highestLevel, 6);
  });

  test('updateDisplayName only touches the row for the matching uid', () async {
    final repo = ProfileRepositoryImpl(db, _FakeRemote(result: _profile('u1')));
    await repo.fetch('u1');

    await repo.updateDisplayName('someone-else', 'Nope');

    // The cached u1 row keeps its name; the mismatched uid updates nothing.
    final cached = await db.cachedProfileDao.read('u1');
    expect(cached?.displayName, 'Player');
  });
}
