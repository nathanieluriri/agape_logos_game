import 'package:agape_logos_game/features/auth/application/auth_providers.dart';
import 'package:agape_logos_game/features/auth/domain/auth_user.dart';
import 'package:agape_logos_game/features/profile/application/profile_providers.dart';
import 'package:agape_logos_game/features/profile/data/profile_remote.dart';
import 'package:agape_logos_game/features/profile/domain/handle_outcome.dart';
import 'package:agape_logos_game/features/profile/domain/profile.dart';
import 'package:agape_logos_game/features/social/application/social_providers.dart';
import 'package:agape_logos_game/features/social/data/social_repository.dart';
import 'package:agape_logos_game/features/social/domain/friend.dart';
import 'package:agape_logos_game/features/social/domain/friend_request.dart';
import 'package:agape_logos_game/features/social/domain/friend_request_outcome.dart';
import 'package:agape_logos_game/features/social/domain/friends_snapshot.dart';
import 'package:agape_logos_game/features/social/domain/match_history_entry.dart';
import 'package:agape_logos_game/features/social/domain/public_profile.dart';
import 'package:agape_logos_game/features/social/domain/public_profile_detail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements SocialRepository {
  bool? lastPrivacy;
  @override
  Future<void> setPrivacy(bool isPublic) async => lastPrivacy = isPublic;
  @override
  Future<List<PublicProfile>> searchUsers(String query) async =>
      const [PublicProfile(uid: 'u2', handle: 'grace', displayName: 'Grace', avatarId: 'avatar_01')];
  @override
  Future<PublicProfileDetail> publicProfile(String uid) async => const PublicProfileDetail(
        profile: PublicProfile(uid: 'u2', handle: 'grace', displayName: 'Grace', avatarId: 'avatar_01'),
        recentMatches: <MatchHistoryEntry>[],
      );
  @override
  Future<FriendRequestOutcome> sendFriendRequest({String? toUid, String? handle}) async =>
      const FriendRequestSent();
  @override
  Future<bool> respondToFriendRequest({required String fromUid, required bool accept}) async => true;
  @override
  Future<FriendsSnapshot> friends() async => const FriendsSnapshot(
        friends: [Friend(uid: 'u2', handle: 'grace', displayName: 'Grace', avatarId: 'avatar_01')],
        requests: [FriendRequest(fromUid: 'u3', handle: 'neo', displayName: 'Neo', avatarId: 'avatar_02')],
      );
  @override
  Future<List<MatchHistoryEntry>> matchHistory({int? limit}) async => const <MatchHistoryEntry>[];
}

class _FakeProfileRemote implements ProfileRemote {
  _FakeProfileRemote(this.isPublic);
  final bool isPublic;
  @override
  Future<Profile> me() async => Profile(
        uid: 'u1', displayName: 'Me', avatarId: 'avatar_01', locale: 'en',
        soundEnabled: true, musicEnabled: true, highestLevel: 3, totalScore: 0,
        coins: 0, createdAt: 1, updatedAt: 2, public: isPublic,
      );
  @override
  Future<int> coins() async => 0;
  @override
  Future<HandleOutcome> setHandle(String handle, {required String idempotencyKey}) async =>
      HandleChanged(handle);
}

ProviderContainer _c({bool signedIn = true, bool serverPublic = true}) => ProviderContainer(
      overrides: [
        socialRepositoryProvider.overrideWithValue(_FakeRepo()),
        profileRemoteProvider.overrideWithValue(_FakeProfileRemote(serverPublic)),
        currentUserProvider.overrideWithValue(signedIn ? const AuthUser(uid: 'u1') : null),
      ],
    );

void main() {
  test('userSearchProvider short-circuits an empty query to an empty list', () async {
    final c = _c();
    addTearDown(c.dispose);
    expect(await c.read(userSearchProvider('   ').future), isEmpty);
    expect((await c.read(userSearchProvider('grace').future)).single.handle, 'grace');
  });

  test('friendsProvider + friendRequestsProvider derive from the snapshot', () async {
    final c = _c();
    addTearDown(c.dispose);
    await c.read(friendsSnapshotProvider.future);
    expect(c.read(friendsProvider).single.uid, 'u2');
    expect(c.read(friendRequestsProvider).single.fromUid, 'u3');
  });

  test('profilePrivacyController reads the server flag then flips optimistically', () async {
    final c = _c(serverPublic: false);
    addTearDown(c.dispose);
    expect(await c.read(profilePrivacyControllerProvider.future), isFalse);
    await c.read(profilePrivacyControllerProvider.notifier).setPublic(true);
    expect(c.read(profilePrivacyControllerProvider).value, isTrue);
  });

  test('privacy defaults false when signed out', () async {
    final c = _c(signedIn: false);
    addTearDown(c.dispose);
    expect(await c.read(profilePrivacyControllerProvider.future), isFalse);
  });
}
