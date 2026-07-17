import 'package:agape_logos_game/features/profile/application/profile_providers.dart';
import 'package:agape_logos_game/features/profile/domain/handle_outcome.dart';
import 'package:agape_logos_game/features/profile/domain/profile.dart';
import 'package:agape_logos_game/features/profile/domain/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Profile _profile(String uid, String displayName) => Profile(
      uid: uid,
      displayName: displayName,
      avatarId: 'avatar_01',
      locale: 'en',
      soundEnabled: true,
      musicEnabled: true,
      highestLevel: 0,
      totalScore: 0,
      coins: 0,
      createdAt: 1000,
      updatedAt: 2000,
    );

class _FakeRepo implements ProfileRepository {
  _FakeRepo(this._profile);
  Profile? _profile;
  int updateCalls = 0;
  String? lastUpdatedName;

  @override
  Future<Profile?> fetch(String uid) async => _profile;

  @override
  Stream<Profile?> watch(String uid) => Stream.value(_profile);

  @override
  Future<int?> fetchCoins(String uid) async => _profile?.coins;

  @override
  Future<void> addCoinsLocally(String uid, int delta) async {
    _profile = _profile?.copyWith(coins: (_profile?.coins ?? 0) + delta);
  }

  @override
  Future<void> advanceLevelLocally(String uid, int level) async {
    final current = _profile?.highestLevel ?? 0;
    if (level > current) {
      _profile = _profile?.copyWith(highestLevel: level);
    }
  }

  @override
  Future<void> updateDisplayName(String uid, String displayName) async {
    updateCalls++;
    lastUpdatedName = displayName;
    _profile = _profile?.copyWith(displayName: displayName);
  }

  @override
  Future<void> clear() async => _profile = null;

  @override
  Future<HandleOutcome> setHandle(String handle) async => HandleChanged(handle);
}

ProviderContainer _containerWith(_FakeRepo repo) {
  final container = ProviderContainer(
    overrides: [profileRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('pushes the Firebase name when the server still holds the default',
      () async {
    final repo = _FakeRepo(_profile('u1', 'Player'));
    final container = _containerWith(repo);

    await container
        .read(profileControllerProvider.notifier)
        .load('u1', firebaseDisplayName: 'Grace Hopper');

    expect(repo.updateCalls, 1);
    expect(repo.lastUpdatedName, 'Grace Hopper');
    expect(
      container.read(profileControllerProvider).value?.displayName,
      'Grace Hopper', // optimistic value surfaced to the UI
    );
  });

  test('re-pushes on a later sign-in if the name never synced (still Player)',
      () async {
    // Simulates the retry: the previous PUT failed, so the server name is
    // still the default on the next sign-in.
    final repo = _FakeRepo(_profile('u1', 'Player'));
    final container = _containerWith(repo);
    final notifier = container.read(profileControllerProvider.notifier);

    await notifier.load('u1', firebaseDisplayName: 'Grace Hopper');
    // Pretend the optimistic value did not stick (server unchanged).
    repo._profile = _profile('u1', 'Player');
    await notifier.load('u1', firebaseDisplayName: 'Grace Hopper');

    expect(repo.updateCalls, 2);
  });

  test('skips the update when the profile already has a custom name', () async {
    final repo = _FakeRepo(_profile('u1', 'Ada Lovelace'));
    final container = _containerWith(repo);

    await container
        .read(profileControllerProvider.notifier)
        .load('u1', firebaseDisplayName: 'Grace Hopper');

    expect(repo.updateCalls, 0);
    expect(
      container.read(profileControllerProvider).value?.displayName,
      'Ada Lovelace',
    );
  });

  test('skips when Firebase provides no usable name', () async {
    final repo = _FakeRepo(_profile('u1', 'Player'));
    final container = _containerWith(repo);

    await container
        .read(profileControllerProvider.notifier)
        .load('u1', firebaseDisplayName: '   ');

    expect(repo.updateCalls, 0);
  });

  test('clamps a long Firebase name to the backend limit', () async {
    final repo = _FakeRepo(_profile('u1', 'Player'));
    final container = _containerWith(repo);
    final longName = 'x' * 50;

    await container
        .read(profileControllerProvider.notifier)
        .load('u1', firebaseDisplayName: longName);

    expect(repo.updateCalls, 1);
    expect(repo.lastUpdatedName!.length, 30);
  });
}
