import 'profile.dart';

/// Boundary for the user profile. `GET /me` is a `CachedRead` (see
/// `core/offline/call_policy.dart`): fetch online with write-through to the
/// local cache, serve the cache when offline.
abstract interface class ProfileRepository {
  /// Fetches the profile for [uid]: online it hits `GET /me` (which provisions
  /// the server document on first read) and writes through to the cache;
  /// offline it returns the cached profile for [uid], or null when absent.
  Future<Profile?> fetch(String uid);

  /// Watches the locally cached profile for [uid]; emits null when absent or
  /// owned by a different account.
  Stream<Profile?> watch(String uid);

  /// `CachedRead` for the wallet only: online it hits `GET /me/coins` and writes
  /// the balance through to the cached profile; offline it returns the cached
  /// balance for [uid] (or null when there is no cached profile). Lighter than
  /// [fetch] when a screen just needs the coin count.
  Future<int?> fetchCoins(String uid);

  /// Optimistically adjusts [uid]'s cached coin balance by [delta] (applied on a
  /// win so the pill updates instantly). The authoritative balance is minted
  /// server-side on puzzle-result sync and reconciles on the next [fetch] /
  /// [fetchCoins].
  Future<void> addCoinsLocally(String uid, int delta);

  /// Optimistically advances [uid]'s cached `highestLevel` to [level] (monotonic
  /// max) so the next-level label updates immediately on a win. The server
  /// applies the same max on puzzle-result sync and reconciles on the next
  /// [fetch].
  Future<void> advanceLevelLocally(String uid, int level);

  /// `OptimisticWrite`: applies [displayName] to the local cache immediately,
  /// then enqueues a `PUT /me` job the sync engine replays when reachable.
  /// Used to push the Firebase display name up when the server still holds the
  /// default "Player".
  Future<void> updateDisplayName(String uid, String displayName);

  /// Clears the cached profile (on sign-out).
  Future<void> clear();
}
