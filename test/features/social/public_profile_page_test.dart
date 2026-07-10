import 'package:agape_logos_game/features/social/application/social_providers.dart';
import 'package:agape_logos_game/features/social/data/social_remote.dart';
import 'package:agape_logos_game/features/social/data/social_repository.dart';
import 'package:agape_logos_game/features/social/domain/friend_request_outcome.dart';
import 'package:agape_logos_game/features/social/domain/friends_snapshot.dart';
import 'package:agape_logos_game/features/social/domain/match_history_entry.dart';
import 'package:agape_logos_game/features/social/domain/public_profile.dart';
import 'package:agape_logos_game/features/social/domain/public_profile_detail.dart';
import 'package:agape_logos_game/features/social/presentation/pages/public_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repo implements SocialRepository {
  _Repo({this.private = false});
  final bool private;
  @override
  Future<void> setPrivacy(bool isPublic) async {}
  @override
  Future<List<PublicProfile>> searchUsers(String query) async => const [];
  @override
  Future<PublicProfileDetail> publicProfile(String uid) async {
    if (private) throw const ProfileNotVisible();
    return const PublicProfileDetail(
      profile: PublicProfile(
        uid: 'u2', handle: 'grace', displayName: 'Grace', avatarId: 'avatar_01',
        highestLevel: 4, totalScore: 120,
      ),
      recentMatches: [
        MatchHistoryEntry(
          matchId: 'm1', opponentUid: 'x', opponentName: 'Rival',
          result: 'win', score: 12, opponentScore: 9, endedAt: 1,
        ),
      ],
    );
  }
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

Widget _host(SocialRepository repo) => ProviderScope(
      overrides: [socialRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: PublicProfilePage(uid: 'u2')),
    );

void main() {
  testWidgets('renders a public profile and its recent match', (tester) async {
    await tester.pumpWidget(_host(_Repo()));
    await tester.pump();
    expect(find.text('Grace'), findsOneWidget);
    expect(find.text('@grace'), findsOneWidget);
    expect(find.text('vs Rival'), findsOneWidget);
  });

  testWidgets('shows a private state when not visible', (tester) async {
    await tester.pumpWidget(_host(_Repo(private: true)));
    await tester.pump();
    expect(find.text('This profile is private.'), findsOneWidget);
  });
}
