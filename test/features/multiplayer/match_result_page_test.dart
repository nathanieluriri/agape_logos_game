import 'package:agape_logos_game/features/auth/application/auth_providers.dart';
import 'package:agape_logos_game/features/auth/domain/auth_user.dart';
import 'package:agape_logos_game/features/multiplayer/application/match_providers.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match_player.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match_settings.dart';
import 'package:agape_logos_game/features/multiplayer/presentation/pages/match_result_page.dart';
import 'package:agape_logos_game/features/game/presentation/widgets/streak_confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

MatchPlayer _p(String uid, int score, {int wordsFound = 0}) => MatchPlayer(
      uid: uid, displayName: uid, avatarId: 'a', isGuest: false, ready: true,
      connected: true, score: score, wordsFound: wordsFound,
    );

Match _finished(
  String winner, {
  Map<String, MatchPlayer>? players,
}) =>
    Match(
      matchId: 'm1', code: 'ABCD', status: MatchStatus.finished,
      participants: const ['me', 'opp'], playerOrder: const ['me', 'opp'],
      createdBy: 'me', createdAt: 0, startedAt: 0, endsAt: 0,
      settings: MatchSettings.defaults(),
      players: players ?? {'me': _p('me', 20), 'opp': _p('opp', 10)},
      winner: winner,
    );

void main() {
  testWidgets('shows the win headline and both scores', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchStreamProvider('m1')
            .overrideWith((ref) => Stream.value(_finished('me'))),
      ],
      child: const MaterialApp(home: MatchResultPage(matchId: 'm1')),
    ));
    await tester.pump();
    expect(find.text('You win'), findsOneWidget);
    expect(find.textContaining('20'), findsOneWidget);
    expect(find.textContaining('10'), findsOneWidget);
    // Rematch is relabelled honestly: the client has no opponent uid to
    // re-challenge the same player, so it opens a new match instead.
    expect(find.text('Play again'), findsOneWidget);
  });

  testWidgets('a win renders the confetti burst', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchStreamProvider('m1')
            .overrideWith((ref) => Stream.value(_finished('me'))),
      ],
      child: const MaterialApp(home: MatchResultPage(matchId: 'm1')),
    ));
    await tester.pump();
    await tester.pump();
    expect(find.byType(StreakConfetti), findsOneWidget);
  });

  testWidgets('a loss renders no confetti burst', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchStreamProvider('m1')
            .overrideWith((ref) => Stream.value(_finished('opp'))),
      ],
      child: const MaterialApp(home: MatchResultPage(matchId: 'm1')),
    ));
    await tester.pump();
    await tester.pump();
    expect(find.byType(StreakConfetti), findsNothing);
  });

  testWidgets('a long opponent name does not overflow the score row',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchStreamProvider('m1').overrideWith(
          (ref) => Stream.value(_finished(
            'me',
            players: {
              'me': _p('me', 20),
              'opp': const MatchPlayer(
                uid: 'opp',
                displayName: 'A Truly Extraordinarily Long Display Name',
                avatarId: 'a',
                isGuest: false,
                ready: true,
                connected: true,
                score: 10,
                wordsFound: 0,
              ),
            },
          )),
        ),
      ],
      child: const MaterialApp(home: MatchResultPage(matchId: 'm1')),
    ));
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('explains a words-found win even with tied scores', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchStreamProvider('m1').overrideWith(
          (ref) => Stream.value(_finished(
            'me',
            players: {
              'me': _p('me', 20, wordsFound: 5),
              'opp': _p('opp', 20, wordsFound: 3),
            },
          )),
        ),
      ],
      child: const MaterialApp(home: MatchResultPage(matchId: 'm1')),
    ));
    await tester.pump();
    expect(find.text('Won by words found'), findsOneWidget);
  });

  testWidgets('a genuine draw shows no reason line', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchStreamProvider('m1').overrideWith(
          (ref) => Stream.value(_finished(
            'draw',
            players: {
              'me': _p('me', 15, wordsFound: 3),
              'opp': _p('opp', 15, wordsFound: 3),
            },
          )),
        ),
      ],
      child: const MaterialApp(home: MatchResultPage(matchId: 'm1')),
    ));
    await tester.pump();
    expect(find.text('Draw'), findsOneWidget);
    expect(find.textContaining('Won by'), findsNothing);
  });

  testWidgets('still loading (no value, no error) shows the spinner',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchStreamProvider('m1')
            .overrideWith((ref) => const Stream<Match?>.empty()),
      ],
      child: const MaterialApp(home: MatchResultPage(matchId: 'm1')),
    ));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('a failed match stream surfaces a retry, not an endless spinner',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchStreamProvider('m1').overrideWith(
          (ref) => Stream<Match?>.error(Exception('permission-denied')),
        ),
      ],
      child: const MaterialApp(home: MatchResultPage(matchId: 'm1')),
    ));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets(
      'a settled-but-null match (deleted doc) shows a retry, not an endless spinner',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchStreamProvider('m1')
            .overrideWith((ref) => Stream<Match?>.value(null)),
      ],
      child: const MaterialApp(home: MatchResultPage(matchId: 'm1')),
    ));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
  });
}
