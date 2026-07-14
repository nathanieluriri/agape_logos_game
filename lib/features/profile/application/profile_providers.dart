import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/profile_remote.dart';
import '../data/profile_repository_impl.dart';
import '../domain/profile.dart';
import '../domain/profile_repository.dart';
import '../profile_config.dart';

final profileRemoteProvider = Provider<ProfileRemote>(
  (ref) => HttpProfileRemote(ref.watch(apiClientProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(profileRemoteProvider),
  ),
);

/// The signed-in user's cached profile, streamed from Drift. The single source
/// of truth every profile-derived value below reads from, so coins and level
/// reflect both server write-throughs (`GET /me`) and optimistic bumps applied
/// on a win. Emits null when signed out or before the first fetch.
final cachedProfileProvider = StreamProvider<Profile?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream<Profile?>.value(null);
  return ref.watch(profileRepositoryProvider).watch(user.uid);
});

/// The signed-in user's coin balance (0 when signed out / before first fetch).
final coinsProvider = Provider<int>(
  (ref) => ref.watch(cachedProfileProvider).value?.coins ?? 0,
);

/// The next level to play, derived from the backend `highestLevel` (the count
/// of levels completed). Level 1 for a brand-new / signed-out player. Used by
/// the game top bar and the level-complete "next" pad.
final nextLevelProvider = Provider<int>(
  (ref) => (ref.watch(cachedProfileProvider).value?.highestLevel ?? 0) + 1,
);

/// Holds the signed-in user's profile for the UI. [load] runs `GET /me` (which
/// provisions the server document on first read and writes through to the
/// cache); [clear] drops the cache on sign-out.
class ProfileController extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async => null;

  /// Fetches the profile for [uid]. When the fetched profile still carries the
  /// server default name and [firebaseDisplayName] holds a usable name, pushes
  /// it up via an optimistic `PUT /me`. Because this runs on every sign-in, it
  /// doubles as the retry: if the first push never synced, the server name is
  /// still "Player" next time and the job is re-enqueued.
  Future<void> load(String uid, {String? firebaseDisplayName}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final ProfileRepository repo = ref.read(profileRepositoryProvider);
      final Profile? profile = await repo.fetch(uid);
      final String? desired = _sanitizeDisplayName(firebaseDisplayName);
      if (profile != null &&
          profile.displayName == kDefaultProfileDisplayName &&
          desired != null &&
          desired != profile.displayName) {
        await repo.updateDisplayName(uid, desired);
        // Reflect the optimistic name in the UI without a refetch.
        return profile.copyWith(displayName: desired);
      }
      return profile;
    });
  }

  /// Refetches the signed-in user's profile (used after a server-authoritative
  /// write such as a handle claim). [build] returns null and only [load]
  /// populates this notifier, so `ref.invalidate(profileControllerProvider)`
  /// would reset the state to null instead of refreshing it.
  Future<void> reload() async {
    final String? uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    await load(uid);
  }

  Future<void> clear() async {
    await ref.read(profileRepositoryProvider).clear();
    state = const AsyncData(null);
  }
}

/// Trims a Firebase display name and clamps it to the backend limit. Returns
/// null when there is no usable name (null or blank), so the caller skips the
/// update rather than sending an empty one.
String? _sanitizeDisplayName(String? name) {
  final String trimmed = (name ?? '').trim();
  if (trimmed.isEmpty) return null;
  return trimmed.length <= kMaxDisplayNameLength
      ? trimmed
      : trimmed.substring(0, kMaxDisplayNameLength);
}

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, Profile?>(ProfileController.new);
