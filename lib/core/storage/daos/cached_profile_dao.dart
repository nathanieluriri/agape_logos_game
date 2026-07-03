import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'cached_profile_dao.g.dart';

/// Reads and writes the single-row [CachedProfile] (id = 0). Reads are guarded
/// by [uid]: a cached row is only surfaced to the account it belongs to, so a
/// guest -> Google switch on one device never shows the previous profile.
@DriftAccessor(tables: [CachedProfile])
class CachedProfileDao extends DatabaseAccessor<AppDatabase>
    with _$CachedProfileDaoMixin {
  CachedProfileDao(super.db);

  /// Write-through: replaces the single cached row with the latest profile.
  Future<void> upsert(CachedProfileCompanion row) =>
      into(cachedProfile).insertOnConflictUpdate(row);

  /// The cached profile for [uid], or null when absent or belonging to a
  /// different account.
  Future<CachedProfileRow?> read(String uid) async {
    final row = await (select(cachedProfile)..where((t) => t.id.equals(0)))
        .getSingleOrNull();
    return (row != null && row.uid == uid) ? row : null;
  }

  /// Watches the cached profile for [uid], emitting null when absent or owned
  /// by a different account.
  Stream<CachedProfileRow?> watch(String uid) =>
      (select(cachedProfile)..where((t) => t.id.equals(0)))
          .watchSingleOrNull()
          .map((row) => (row != null && row.uid == uid) ? row : null);

  /// Optimistically updates just the display name for [uid]'s cached row (used
  /// by the `PUT /me` optimistic write, applied before the server confirms).
  Future<void> setDisplayName(String uid, String displayName) =>
      (update(cachedProfile)
            ..where((t) => t.id.equals(0) & t.uid.equals(uid)))
          .write(CachedProfileCompanion(displayName: Value(displayName)));

  /// Write-through for the coin-only read (`GET /me/coins`): sets the balance on
  /// [uid]'s cached row without touching the rest of the profile.
  Future<void> setCoins(String uid, int coins) =>
      (update(cachedProfile)..where((t) => t.id.equals(0) & t.uid.equals(uid)))
          .write(CachedProfileCompanion(coins: Value(coins)));

  /// Optimistically adjusts [uid]'s cached balance by [delta] (applied on a win
  /// before the server confirms; the authoritative value reconciles on the next
  /// `GET /me` / `GET /me/coins`). No-op when no row belongs to [uid].
  Future<void> addCoins(String uid, int delta) => transaction(() async {
        final row = await read(uid);
        if (row == null) return;
        await setCoins(uid, row.coins + delta);
      });

  /// Optimistically advances [uid]'s cached `highestLevel` to [level] (monotonic
  /// max), so the next-level label moves the instant a level is won. The server
  /// applies the same max on result sync and reconciles on the next `GET /me`.
  /// No-op when no row belongs to [uid].
  Future<void> bumpHighestLevel(String uid, int level) => transaction(() async {
        final row = await read(uid);
        if (row == null) return;
        if (level <= row.highestLevel) return;
        await (update(cachedProfile)
              ..where((t) => t.id.equals(0) & t.uid.equals(uid)))
            .write(CachedProfileCompanion(highestLevel: Value(level)));
      });

  /// Drops the cached profile (called on sign-out / account deletion).
  Future<void> clear() => delete(cachedProfile).go();
}
