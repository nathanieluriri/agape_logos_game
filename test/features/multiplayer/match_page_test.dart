import 'package:agape_logos_game/features/auth/application/auth_providers.dart';
import 'package:agape_logos_game/features/auth/domain/auth_user.dart';
import 'package:agape_logos_game/features/multiplayer/application/match_providers.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match_event.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match_player.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match_rack.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match_settings.dart';
import 'package:agape_logos_game/features/multiplayer/presentation/pages/match_page.dart';
import 'package:agape_logos_game/features/puzzles/domain/puzzle.dart';
import 'package:agape_logos_game/features/store/application/store_providers.dart';
import 'package:agape_logos_game/features/store/domain/store_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

MatchPlayer _p(String uid, {int score = 0}) => MatchPlayer(
      uid: uid, displayName: uid, avatarId: 'a', isGuest: false, ready: true,
      connected: true, score: score, wordsFound: 0,
    );

Match _active() => Match(
      matchId: 'm1', code: 'ABCD', status: MatchStatus.active,
      participants: const ['me', 'opp'], playerOrder: const ['me', 'opp'],
      createdBy: 'me', createdAt: 0, startedAt: 0,
      endsAt: DateTime.now().millisecondsSinceEpoch + 90000,
      settings: MatchSettings.defaults(),
      players: {'me': _p('me', score: 7), 'opp': _p('opp', score: 3)},
      winner: null,
    );

MatchRack _rack() => const MatchRack(
      uid: 'me', letters: ['I', 'F'], letterKey: 'FI', rackSize: 2,
      answers: [PuzzleAnswer(word: 'IF', length: 2, definition: null)],
      answerCount: 1, foundWords: [],
    );

void main() {
  testWidgets('active match renders the board, wheel, timer, and scores',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchStreamProvider('m1').overrideWith((ref) => Stream.value(_active())),
        myRackStreamProvider('m1').overrideWith((ref) => Stream.value(_rack())),
        matchEventsStreamProvider('m1')
            .overrideWith((ref) => Stream.value(const <MatchEvent>[])),
        storeCatalogProvider.overrideWith((ref) async => const <StoreItem>[]),
      ],
      child: const MaterialApp(home: MatchPage(matchId: 'm1')),
    ));
    await tester.pump(); // streams emit
    await tester.pump(); // rack sync + rebuild
    expect(find.text('I'), findsWidgets);
    expect(find.text('F'), findsWidgets);
    expect(find.text('7'), findsOneWidget); // my score
    expect(find.text('opp'), findsOneWidget); // opponent HUD name
  });

  // Regression: the server parks the doc in `countdown` and only flips it to
  // `active` on the next submit/powerup (settleMatch). Gating the board on
  // status == active deadlocked the match: no board -> no submit -> no flip, so
  // the page sat on "Get ready..." forever. The board opens on startedAt.
  testWidgets('a countdown match past startedAt opens the board', (tester) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final counting = _active().copyWith(
      status: MatchStatus.countdown,
      startedAt: now - 1000, // the go instant already passed
      endsAt: now + 90000,
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchStreamProvider('m1').overrideWith((ref) => Stream.value(counting)),
        myRackStreamProvider('m1').overrideWith((ref) => Stream.value(_rack())),
        matchEventsStreamProvider('m1')
            .overrideWith((ref) => Stream.value(const <MatchEvent>[])),
        storeCatalogProvider.overrideWith((ref) async => const <StoreItem>[]),
      ],
      child: const MaterialApp(home: MatchPage(matchId: 'm1')),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Get ready'), findsNothing);
    expect(find.text('I'), findsWidgets); // the rack is on screen: playable
  });
}
