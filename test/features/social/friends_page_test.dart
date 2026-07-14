import 'package:agape_logos_game/core/firebase/firestore_providers.dart';
import 'package:agape_logos_game/features/auth/application/auth_providers.dart';
import 'package:agape_logos_game/features/auth/domain/auth_user.dart';
import 'package:agape_logos_game/features/social/application/social_providers.dart';
import 'package:agape_logos_game/features/social/data/social_repository.dart';
import 'package:agape_logos_game/features/social/domain/friend.dart';
import 'package:agape_logos_game/features/social/domain/friend_request.dart';
import 'package:agape_logos_game/features/social/domain/friend_request_outcome.dart';
import 'package:agape_logos_game/features/social/domain/friends_snapshot.dart';
import 'package:agape_logos_game/features/social/domain/match_history_entry.dart';
import 'package:agape_logos_game/features/social/domain/public_profile.dart';
import 'package:agape_logos_game/features/social/domain/public_profile_detail.dart';
import 'package:agape_logos_game/features/social/presentation/pages/friends_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements SocialRepository {
  int respondCalls = 0;
  bool? lastAccept;
  @override
  Future<void> setPrivacy(bool isPublic) async {}
  @override
  Future<List<PublicProfile>> searchUsers(String query) async => const [];
  @override
  Future<PublicProfileDetail> publicProfile(String uid) async => const PublicProfileDetail(
        profile: PublicProfile(uid: 'u2', handle: 'h', displayName: 'n', avatarId: 'avatar_01'),
        recentMatches: <MatchHistoryEntry>[],
      );
  @override
  Future<FriendRequestOutcome> sendFriendRequest({String? toUid, String? handle}) async =>
      const FriendRequestSent();
  @override
  Future<bool> respondToFriendRequest({required String fromUid, required bool accept}) async {
    respondCalls++;
    lastAccept = accept;
    return true;
  }
  @override
  Future<FriendsSnapshot> friends() async => const FriendsSnapshot(
        friends: [Friend(uid: 'u2', handle: 'grace', displayName: 'Grace', avatarId: 'avatar_01')],
        requests: [FriendRequest(fromUid: 'u3', handle: 'neo', displayName: 'Neo', avatarId: 'avatar_02')],
      );
  @override
  Future<List<MatchHistoryEntry>> matchHistory({int? limit}) async => const [];
}

/// A fake Firestore seeded with one friend (Grace) and one incoming request
/// (Neo) under `users/u1`, matching what the live listeners read.
FakeFirebaseFirestore _seededDb() {
  final db = FakeFirebaseFirestore();
  db.collection('users').doc('u1').collection('friends').doc('u2').set({
    'uid': 'u2',
    'handle': 'grace',
    'displayName': 'Grace',
    'avatarId': 'avatar_01',
    'since': Timestamp.fromMillisecondsSinceEpoch(1000),
  });
  db.collection('users').doc('u1').collection('friendRequests').doc('u3').set({
    'fromUid': 'u3',
    'handle': 'neo',
    'displayName': 'Neo',
    'avatarId': 'avatar_02',
    'at': Timestamp.fromMillisecondsSinceEpoch(1000),
  });
  return db;
}

Widget _host(
  SocialRepository repo, {
  FriendsTab tab = FriendsTab.friends,
  FakeFirebaseFirestore? db,
}) => ProviderScope(
      overrides: [
        socialRepositoryProvider.overrideWithValue(repo),
        firebaseFirestoreProvider.overrideWithValue(db ?? _seededDb()),
        authStateProvider.overrideWith(
          (ref) => Stream.value(const AuthUser(uid: 'u1')),
        ),
      ],
      child: MaterialApp(home: FriendsPage(initialTab: tab)),
    );

void main() {
  testWidgets('friends list shows a friend', (tester) async {
    await tester.pumpWidget(_host(_FakeRepo()));
    await tester.pump(); // auth restores
    await tester.pump(); // live friends listener emits
    expect(find.text('Grace'), findsOneWidget);
    expect(find.text('@grace'), findsOneWidget);
  });

  testWidgets('requests pane accepts a request', (tester) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(_host(repo, tab: FriendsTab.requests));
    await tester.pump(); // auth restores
    await tester.pump(); // live requests listener emits
    expect(find.text('Neo'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Accept Neo'));
    await tester.pump();
    expect(repo.respondCalls, 1);
    expect(repo.lastAccept, isTrue);
  });
}
