import 'package:agape_logos_game/features/auth/application/auth_providers.dart';
import 'package:agape_logos_game/features/auth/domain/auth_user.dart';
import 'package:agape_logos_game/features/multiplayer/application/match_providers.dart';
import 'package:agape_logos_game/features/multiplayer/data/match_remote.dart';
import 'package:agape_logos_game/features/multiplayer/domain/active_match.dart';
import 'package:agape_logos_game/features/multiplayer/domain/challenge_outcome.dart';
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

/// Records the settling GET the page pokes at each clock boundary.
class _FakeRemote implements MatchRemote {
  final List<String> settled = <String>[];
  final List<String> left = <String>[];

  @override
  Future<void> settle(String matchId) async => settled.add(matchId);

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
  Future<PowerupFireResult> powerup(
    String m,
    String k, {
    required String eventId,
  }) async => (ok: true, reason: null);
  @override
  Future<void> leave(String matchId) async => left.add(matchId);

  @override
  Future<ChallengeOutcome> challenge(String toUid, {required String mode}) async =>
      const ChallengeSent('m1');

  @override
  Future<void> respondChallenge(String matchId, {required bool accept}) async {}

  @override
  Future<List<ActiveMatch>> activeMatches() async => const [];
}

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

Match _asyncActive() => _active().copyWith(
      settings: MatchSettings.defaults().copyWith(mode: MatchMode.async),
    );

MatchRack _rack() => const MatchRack(
      uid: 'me', letters: ['I', 'F'], letterKey: 'FI', rackSize: 2,
      answers: [PuzzleAnswer(word: 'IF', length: 2, definition: null)],
      answerCount: 1, foundWords: [],
    );

void main() {
  testWidgets('active match renders the board, wheel, timer, and scores',
      (tester) async {
    final remote = _FakeRemote();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchServiceProvider.overrideWithValue(remote),
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
    final remote = _FakeRemote();
    final now = DateTime.now().millisecondsSinceEpoch;
    final counting = _active().copyWith(
      status: MatchStatus.countdown,
      startedAt: now - 1000, // the go instant already passed
      endsAt: now + 90000,
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchServiceProvider.overrideWithValue(remote),
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
    // ...and it pokes the settling GET so the doc actually reaches `active`
    // for BOTH players, rather than relying on someone submitting a word.
    expect(remote.settled, <String>['m1']);
  });

  // The other half of the same hole: if neither player ever submits, nothing
  // calls settleMatch, so the match never finalizes at endsAt either and both
  // players sit on a dead board until the scheduled sweeper cancels it.
  testWidgets('an expired match holds and pokes the server to finalize',
      (tester) async {
    final remote = _FakeRemote();
    final now = DateTime.now().millisecondsSinceEpoch;
    final expired = _active().copyWith(startedAt: now - 90000, endsAt: now - 1);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchServiceProvider.overrideWithValue(remote),
        matchStreamProvider('m1').overrideWith((ref) => Stream.value(expired)),
        myRackStreamProvider('m1').overrideWith((ref) => Stream.value(_rack())),
        matchEventsStreamProvider('m1')
            .overrideWith((ref) => Stream.value(const <MatchEvent>[])),
        storeCatalogProvider.overrideWith((ref) async => const <StoreItem>[]),
      ],
      child: const MaterialApp(home: MatchPage(matchId: 'm1')),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining("Time's up"), findsOneWidget);
    expect(remote.settled, <String>['m1']);
  });

  // An async (6-hour) match is played across sittings: leaving the screen is
  // NORMAL and must NOT forfeit. Back pops straight out, shows no forfeit
  // dialog, and never calls leave (the game keeps running server-side).
  testWidgets('an async match pops on back WITHOUT a forfeit dialog or leave',
      (tester) async {
    final remote = _FakeRemote();
    final navKey = GlobalKey<NavigatorState>();

    Widget host(Widget child) => ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
            matchServiceProvider.overrideWithValue(remote),
            matchStreamProvider('m1')
                .overrideWith((ref) => Stream.value(_asyncActive())),
            myRackStreamProvider('m1').overrideWith((ref) => Stream.value(_rack())),
            matchEventsStreamProvider('m1')
                .overrideWith((ref) => Stream.value(const <MatchEvent>[])),
            storeCatalogProvider.overrideWith((ref) async => const <StoreItem>[]),
          ],
          child: MaterialApp(navigatorKey: navKey, home: child),
        );

    await tester.pumpWidget(host(
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MatchPage(matchId: 'm1'),
              ),
            ),
            child: const Text('Go'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();
    // The match board is up (no forfeit flag button for async).
    expect(find.text('7'), findsOneWidget);
    expect(find.bySemanticsLabel('Leave match'), findsNothing);

    // System back: async pops cleanly.
    await navKey.currentState!.maybePop();
    await tester.pumpAndSettle();

    expect(find.text('Leave the match?'), findsNothing); // no forfeit confirm
    expect(remote.left, isEmpty); // never forfeited
    expect(find.text('Go'), findsOneWidget); // popped back to the caller
  });
}
