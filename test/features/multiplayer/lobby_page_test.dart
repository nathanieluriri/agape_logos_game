import 'dart:async';

import 'package:agape_logos_game/features/auth/application/auth_providers.dart';
import 'package:agape_logos_game/features/auth/domain/auth_user.dart';
import 'package:agape_logos_game/features/multiplayer/application/match_providers.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match_player.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match_settings.dart';
import 'package:agape_logos_game/features/multiplayer/presentation/pages/lobby_page.dart';
import 'package:agape_logos_game/shared/widgets/pond_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

MatchPlayer _p(String uid) => MatchPlayer(
      uid: uid, displayName: uid, avatarId: 'a', isGuest: false, ready: false,
      connected: true, score: 0, wordsFound: 0,
    );

Match _lobby() => Match(
      matchId: 'm1', code: 'ABCD', status: MatchStatus.lobby,
      participants: const ['me'], playerOrder: const ['me'], createdBy: 'me',
      createdAt: 0, startedAt: 0, endsAt: 0, settings: MatchSettings.defaults(),
      players: {'me': _p('me')}, winner: null,
    );

void main() {
  testWidgets('lobby shows the code and a ready action', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchStreamProvider('m1').overrideWith((ref) => Stream.value(_lobby())),
      ],
      child: const MaterialApp(home: LobbyPage(matchId: 'm1')),
    ));
    await tester.pump();
    expect(find.text('ABCD'), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('Waiting for an opponent to join...'), findsOneWidget);
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
      child: const MaterialApp(home: LobbyPage(matchId: 'm1')),
    ));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('the empty-seat wait state shows a living loader',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchStreamProvider('m1').overrideWith((ref) => Stream.value(_lobby())),
      ],
      child: const MaterialApp(home: LobbyPage(matchId: 'm1')),
    ));
    await tester.pump();

    expect(find.byType(PondLoader), findsOneWidget);
    expect(find.text('Still searching... share the code above to speed it up.'),
        findsNothing);
  });

  testWidgets('an opponent joining shows a "joined" confirmation',
      (tester) async {
    final controller = StreamController<Match?>();
    addTearDown(controller.close);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchStreamProvider('m1').overrideWith((ref) => controller.stream),
      ],
      child: const MaterialApp(home: LobbyPage(matchId: 'm1')),
    ));

    controller.add(_lobby());
    await tester.pump();
    expect(find.textContaining('joined!'), findsNothing);

    controller.add(Match(
      matchId: 'm1', code: 'ABCD', status: MatchStatus.lobby,
      participants: const ['me', 'opp'],
      playerOrder: const ['me', 'opp'], createdBy: 'me',
      createdAt: 0, startedAt: 0, endsAt: 0, settings: MatchSettings.defaults(),
      players: {'me': _p('me'), 'opp': _p('opp')}, winner: null,
    ));
    await tester.pump();

    expect(find.text('opp joined!'), findsOneWidget);
  });
}
