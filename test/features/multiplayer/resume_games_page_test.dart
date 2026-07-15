import 'package:agape_logos_game/features/multiplayer/application/match_providers.dart';
import 'package:agape_logos_game/features/multiplayer/application/resume_providers.dart';
import 'package:agape_logos_game/features/multiplayer/data/match_remote.dart';
import 'package:agape_logos_game/features/multiplayer/domain/active_match.dart';
import 'package:agape_logos_game/features/multiplayer/domain/challenge_invite.dart';
import 'package:agape_logos_game/features/multiplayer/domain/challenge_outcome.dart';
import 'package:agape_logos_game/features/multiplayer/presentation/pages/resume_games_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Records the challenge responses the page fires.
class _FakeRemote implements MatchRemote {
  final List<({String matchId, bool accept})> responded = [];

  @override
  Future<void> respondChallenge(String matchId, {required bool accept}) async =>
      responded.add((matchId: matchId, accept: accept));

  @override
  Future<List<ActiveMatch>> activeMatches() async => const [];

  @override
  Future<({String matchId, String code})> create(Map<String, dynamic> s) async =>
      (matchId: 'm1', code: 'ABCD');
  @override
  Future<String> join(String code) async => 'm1';
  @override
  Future<void> ready(String matchId, {required bool ready}) async {}
  @override
  Future<void> start(String matchId) async {}
  @override
  Future<void> submit(String matchId, String word) async {}
  @override
  Future<bool> powerup(String m, String k, {required String eventId}) async =>
      true;
  @override
  Future<void> leave(String matchId) async {}
  @override
  Future<void> settle(String matchId) async {}
  @override
  Future<ChallengeOutcome> challenge(String toUid, {required String mode}) async =>
      const ChallengeSent('m1');
}

ChallengeInvite _invite() => const ChallengeInvite(
      matchId: 'c1',
      byUid: 'u2',
      handle: 'grace',
      displayName: 'Grace',
      avatarId: 'a',
      mode: 'async',
      at: 1,
    );

ActiveMatch _match() => const ActiveMatch(
      matchId: 'm9',
      mode: 'async',
      status: 'active',
      opponentUid: 'u3',
      opponentName: 'Sam',
      myScore: 5,
      opponentScore: 2,
      startedAt: 0,
      endsAt: 0,
    );

Widget _host(_FakeRemote remote) {
  final router = GoRouter(
    initialLocation: '/multiplayer/resume',
    routes: [
      GoRoute(
        path: '/multiplayer/resume',
        builder: (_, __) => const ResumeGamesPage(),
      ),
      GoRoute(
        path: '/multiplayer/match/:id',
        builder: (_, s) => Text('Match ${s.pathParameters['id']}'),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      matchServiceProvider.overrideWithValue(remote),
      incomingChallengesProvider.overrideWith((ref) => Stream.value([_invite()])),
      activeMatchesProvider.overrideWith((ref) async => [_match()]),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('renders an incoming challenge and an active match row',
      (tester) async {
    await tester.pumpWidget(_host(_FakeRemote()));
    await tester.pumpAndSettle();

    expect(find.text('Grace challenged you'), findsOneWidget);
    expect(find.text('6-hour game'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
    // The active match row.
    expect(find.text('Sam'), findsOneWidget);
    expect(find.text('5 - 2'), findsOneWidget);
  });

  testWidgets('tapping Accept calls respondChallenge(accept: true)',
      (tester) async {
    final remote = _FakeRemote();
    await tester.pumpWidget(_host(remote));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    expect(remote.responded, [(matchId: 'c1', accept: true)]);
  });
}
