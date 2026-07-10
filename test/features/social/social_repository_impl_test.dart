import 'package:agape_logos_game/features/social/data/social_remote.dart';
import 'package:agape_logos_game/features/social/data/social_repository_impl.dart';
import 'package:agape_logos_game/features/social/domain/friend.dart';
import 'package:agape_logos_game/features/social/domain/friend_request.dart';
import 'package:agape_logos_game/features/social/domain/friend_request_outcome.dart';
import 'package:agape_logos_game/features/social/domain/friends_snapshot.dart';
import 'package:agape_logos_game/features/social/domain/match_history_entry.dart';
import 'package:agape_logos_game/features/social/domain/public_profile.dart';
import 'package:agape_logos_game/features/social/domain/public_profile_detail.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRemote implements SocialRemote {
  bool? lastPrivacy;
  String? lastSearch;
  String? reqToUid;
  String? reqHandle;
  String? respondFrom;
  bool? respondAccept;
  final List<String> keys = <String>[];

  @override
  Future<void> setPrivacy(bool isPublic, {required String idempotencyKey}) async {
    lastPrivacy = isPublic;
    keys.add(idempotencyKey);
  }

  @override
  Future<List<PublicProfile>> searchUsers(String query) async {
    lastSearch = query;
    return const [PublicProfile(uid: 'u2', handle: 'grace', displayName: 'Grace', avatarId: 'avatar_01')];
  }

  @override
  Future<PublicProfileDetail> publicProfile(String uid) async => const PublicProfileDetail(
        profile: PublicProfile(uid: 'u2', handle: 'grace', displayName: 'Grace', avatarId: 'avatar_01'),
        recentMatches: <MatchHistoryEntry>[],
      );

  @override
  Future<FriendRequestOutcome> sendFriendRequest({
    String? toUid,
    String? handle,
    required String idempotencyKey,
  }) async {
    reqToUid = toUid;
    reqHandle = handle;
    keys.add(idempotencyKey);
    return const FriendRequestSent();
  }

  @override
  Future<bool> respondToFriendRequest({
    required String fromUid,
    required bool accept,
    required String idempotencyKey,
  }) async {
    respondFrom = fromUid;
    respondAccept = accept;
    keys.add(idempotencyKey);
    return true;
  }

  @override
  Future<FriendsSnapshot> friends() async => const FriendsSnapshot(
        friends: [Friend(uid: 'u2', handle: 'grace', displayName: 'Grace', avatarId: 'avatar_01')],
        requests: [FriendRequest(fromUid: 'u3', handle: 'neo', displayName: 'Neo', avatarId: 'avatar_02')],
      );

  @override
  Future<List<MatchHistoryEntry>> matchHistory({int? limit}) async =>
      const <MatchHistoryEntry>[];
}

void main() {
  test('setPrivacy delegates and passes a non-empty idempotency key', () async {
    final remote = _FakeRemote();
    final repo = SocialRepositoryImpl(remote);
    await repo.setPrivacy(true);
    expect(remote.lastPrivacy, isTrue);
    expect(remote.keys.single, isNotEmpty);
  });

  test('sendFriendRequest forwards handle and a fresh key each call', () async {
    final remote = _FakeRemote();
    final repo = SocialRepositoryImpl(remote);
    final outcome = await repo.sendFriendRequest(handle: 'grace');
    expect(outcome, isA<FriendRequestSent>());
    expect(remote.reqHandle, 'grace');
    await repo.sendFriendRequest(toUid: 'u9');
    expect(remote.keys.toSet().length, 2); // two distinct keys
  });

  test('respond and reads pass through', () async {
    final remote = _FakeRemote();
    final repo = SocialRepositoryImpl(remote);
    expect(await repo.respondToFriendRequest(fromUid: 'u3', accept: true), isTrue);
    expect(remote.respondAccept, isTrue);
    final snap = await repo.friends();
    expect(snap.friends.single.uid, 'u2');
    expect(snap.requests.single.fromUid, 'u3');
    expect((await repo.searchUsers('gr')).single.handle, 'grace');
  });
}
