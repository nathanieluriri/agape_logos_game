import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/offline/mutation.dart';
import '../../../core/offline/offline_aware_repository.dart';
import '../../../core/storage/app_database.dart';
import '../domain/handle_outcome.dart';
import '../domain/profile.dart';
import '../domain/profile_repository.dart';
import '../profile_config.dart';
import 'pending_wallet.dart';
import 'profile_mappers.dart';
import 'profile_remote.dart';

/// Implementation of [ProfileRepository]. `GET /me` is a `CachedRead`
/// (networkFirst: fetch online with write-through, serve cache offline); the
/// display-name push is an `OptimisticWrite` (apply locally, enqueue `PUT /me`).
class ProfileRepositoryImpl
    with OfflineAwareRepository
    implements ProfileRepository {
  ProfileRepositoryImpl(this.db, this._remote, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  @override
  final AppDatabase db;
  final ProfileRemote _remote;
  final Uuid _uuid;

  @override
  Future<Profile?> fetch(String uid) async {
    try {
      final Profile profile = await _remote.me();
      // Petals still in the offline queue are added on top of the server
      // balance, so a server snapshot taken before the queued winnings synced
      // can never clobber the optimistic balance the player is looking at.
      final int delta = await pendingCoinDelta(db);
      await db.cachedProfileDao.mergeServerProfile(
        profileToCompanion(profile),
        pendingCoinDelta: delta,
      );
      // Return what the merge produced, not the raw server snapshot: coins
      // carry the in-transit delta, and the level is max-protected the same
      // way the cache merge protects it, so direct readers of the returned
      // profile (profileControllerProvider) can never see a stale level.
      final row = await db.cachedProfileDao.read(uid);
      final int level = row == null
          ? profile.highestLevel
          : max(row.highestLevel, profile.highestLevel);
      return profile.copyWith(
        coins: profile.coins + delta,
        highestLevel: level,
      );
    } on DioException catch (e) {
      // Offline or transient: serve the cached profile for this account.
      logger.info('profile fetch offline, serving cache: ${e.message}');
      final row = await db.cachedProfileDao.read(uid);
      return row == null ? null : profileFromRow(row);
    }
  }

  @override
  Stream<Profile?> watch(String uid) => db.cachedProfileDao
      .watch(uid)
      .map((row) => row == null ? null : profileFromRow(row));

  @override
  Future<int?> fetchCoins(String uid) async {
    try {
      final int coins = await _remote.coins();
      // Same reconciliation as [fetch]: the server balance plus whatever the
      // offline queue still owes it. Write through only when a cached profile
      // for this account exists; the coins column lives on that single row. If
      // none exists yet, a full `fetch` (GET /me) will seed the row.
      final int delta = await pendingCoinDelta(db);
      await db.cachedProfileDao.setCoins(uid, coins + delta);
      return coins + delta;
    } on DioException catch (e) {
      logger.info('coins fetch offline, serving cache: ${e.message}');
      final row = await db.cachedProfileDao.read(uid);
      return row?.coins;
    }
  }

  @override
  Future<void> addCoinsLocally(String uid, int delta) =>
      db.cachedProfileDao.addCoins(uid, delta);

  @override
  Future<void> advanceLevelLocally(String uid, int level) =>
      db.cachedProfileDao.bumpHighestLevel(uid, level);

  @override
  Future<void> updateDisplayName(String uid, String displayName) async {
    // 1) Apply locally NOW so the UI shows the real name immediately.
    await db.cachedProfileDao.setDisplayName(uid, displayName);
    // 2) Enqueue the PUT /me job for the sync engine to replay. The idempotency
    // key is per-uid: PUT is naturally idempotent, and reusing the key keeps a
    // re-enqueue (a later sign-in that finds the name still unsynced) from
    // stacking distinct server-visible operations.
    await enqueueMutation(
      PendingMutationData(
        id: _uuid.v4(),
        endpoint: '/me',
        method: 'PUT',
        payloadJson: jsonEncode(<String, String>{'displayName': displayName}),
        idempotencyKey: 'profile-name-$uid',
        kind: kProfileDisplayNameKind,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Future<void> clear() => db.cachedProfileDao.clear();

  @override
  Future<HandleOutcome> setHandle(String handle) =>
      _remote.setHandle(handle, idempotencyKey: _uuid.v4());
}
