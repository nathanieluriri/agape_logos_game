import 'package:agape_logos_game/features/auth/application/auth_providers.dart';
import 'package:agape_logos_game/features/auth/domain/auth_user.dart';
import 'package:agape_logos_game/features/profile/application/profile_providers.dart';
import 'package:agape_logos_game/features/profile/data/profile_remote.dart';
import 'package:agape_logos_game/features/profile/domain/handle_outcome.dart';
import 'package:agape_logos_game/features/profile/domain/profile.dart';
import 'package:agape_logos_game/features/settings/presentation/widgets/public_profile_switch_row.dart';
import 'package:agape_logos_game/features/social/application/social_providers.dart';
import 'package:agape_logos_game/features/social/data/social_repository.dart';
import 'package:agape_logos_game/features/social/domain/friend_request_outcome.dart';
import 'package:agape_logos_game/features/social/domain/friends_snapshot.dart';
import 'package:agape_logos_game/features/social/domain/match_history_entry.dart';
import 'package:agape_logos_game/features/social/domain/public_profile.dart';
import 'package:agape_logos_game/features/social/domain/public_profile_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repo implements SocialRepository {
  bool? lastSet;
  @override
  Future<void> setPrivacy(bool isPublic) async => lastSet = isPublic;
  @override
  Future<List<PublicProfile>> searchUsers(String q) async => const [];
  @override
  Future<PublicProfileDetail> publicProfile(String uid) async => const PublicProfileDetail(
        profile: PublicProfile(uid: 'u2', handle: 'h', displayName: 'n', avatarId: 'avatar_01'),
        recentMatches: <MatchHistoryEntry>[],
      );
  @override
  Future<FriendRequestOutcome> sendFriendRequest({String? toUid, String? handle}) async =>
      const FriendRequestSent();
  @override
  Future<bool> respondToFriendRequest({required String fromUid, required bool accept}) async => true;
  @override
  Future<FriendsSnapshot> friends() async => FriendsSnapshot.empty;
  @override
  Future<List<MatchHistoryEntry>> matchHistory({int? limit}) async => const [];
}

class _ProfileRemote implements ProfileRemote {
  @override
  Future<Profile> me() async => const Profile(
        uid: 'u1', displayName: 'Me', avatarId: 'avatar_01', locale: 'en',
        soundEnabled: true, musicEnabled: true, highestLevel: 3, totalScore: 0,
        coins: 0, createdAt: 1, updatedAt: 2, public: false,
      );
  @override
  Future<int> coins() async => 0;
  @override
  Future<HandleOutcome> setHandle(String handle, {required String idempotencyKey}) async =>
      HandleChanged(handle);
}

void main() {
  testWidgets('toggling Public profile calls setPrivacy(true)', (tester) async {
    final repo = _Repo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          socialRepositoryProvider.overrideWithValue(repo),
          profileRemoteProvider.overrideWithValue(_ProfileRemote()),
          currentUserProvider.overrideWithValue(const AuthUser(uid: 'u1')),
        ],
        child: const MaterialApp(
          home: Scaffold(body: PublicProfileSwitchRow()),
        ),
      ),
    );
    await tester.pump(); // resolve the privacy build (server flag = false)

    expect(find.text('Public profile'), findsOneWidget);
    await tester.tap(find.text('Public profile')); // the row toggles the switch
    await tester.pump();
    expect(repo.lastSet, isTrue);
  });
}
