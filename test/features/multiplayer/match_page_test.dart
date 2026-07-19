import 'dart:async';

import 'package:agape_logos_game/core/audio/audio_providers.dart';
import 'package:agape_logos_game/core/audio/audio_service.dart';
import 'package:agape_logos_game/core/audio/sfx_keys.dart';
import 'package:agape_logos_game/core/connectivity/connectivity_providers.dart';
import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:agape_logos_game/features/auth/application/auth_providers.dart';
import 'package:agape_logos_game/features/auth/domain/auth_user.dart';
import 'package:agape_logos_game/features/multiplayer/application/match_controller.dart';
import 'package:agape_logos_game/features/multiplayer/application/match_providers.dart';
import 'package:agape_logos_game/features/multiplayer/application/resume_providers.dart';
import 'package:agape_logos_game/features/multiplayer/application/server_clock.dart';
import 'package:agape_logos_game/features/multiplayer/data/match_leave_repository.dart';
import 'package:agape_logos_game/features/multiplayer/data/match_remote.dart';
import 'package:agape_logos_game/features/multiplayer/domain/multiplayer_config.dart';
import 'package:agape_logos_game/features/multiplayer/domain/active_match.dart';
import 'package:agape_logos_game/features/multiplayer/domain/challenge_outcome.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match_event.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match_player.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match_rack.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match_settings.dart';
import 'package:agape_logos_game/features/multiplayer/presentation/pages/match_page.dart';
import 'package:agape_logos_game/features/game/presentation/widgets/combo_banner.dart';
import 'package:agape_logos_game/features/game/presentation/widgets/letter_wheel.dart';
import 'package:agape_logos_game/features/game/presentation/widgets/streak_confetti.dart';
import 'package:agape_logos_game/features/puzzles/domain/puzzle.dart';
import 'package:agape_logos_game/features/social/application/social_providers.dart';
import 'package:agape_logos_game/features/social/domain/match_history_entry.dart';
import 'package:agape_logos_game/features/store/application/store_providers.dart';
import 'package:agape_logos_game/features/store/domain/store_item.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Records the settling GET the page pokes at each clock boundary. `leave` is
/// still implemented (part of the interface) and records to [left] so a test
/// can assert the forfeit no longer fires a bare call straight at the remote.
class _FakeRemote implements MatchRemote {
  final List<String> settled = <String>[];
  final List<String> left = <String>[];

  /// When set, [powerup] throws this instead of returning a result: stands in
  /// for a rethrown server error (409 "nothing to steal", offline
  /// DioException, ...) that `MatchRemote.powerup` does not map to a result.
  Object? powerupError;

  /// An artificial latency before [powerup] resolves (or throws), so a test can
  /// observe the optimistic inventory decrement in the gap before the server
  /// answers, rather than the decrement and its refund collapsing into one
  /// microtask turn.
  Duration powerupDelay = Duration.zero;

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
  }) async {
    if (powerupDelay > Duration.zero) await Future<void>.delayed(powerupDelay);
    final error = powerupError;
    if (error != null) throw error;
    return (ok: true, reason: null);
  }
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

/// Records every SFX key `AudioService.playSfx` is called with, so a test can
/// assert a match moment cued the right cue without a real audio backend.
class _FakeAudio implements AudioService {
  final List<String> played = <String>[];
  @override
  Future<void> preload(List<String> sfx) async {}
  @override
  Future<void> playSfx(String name) async {
    played.add(name);
  }
  @override
  void setMuted(bool muted) {}
}

MatchPlayer _p(
  String uid, {
  int score = 0,
  int wordsFound = 0,
  int endsAtBonusMs = 0,
  int lastSeen = 0,
}) =>
    MatchPlayer(
      uid: uid, displayName: uid, avatarId: 'a', isGuest: false, ready: true,
      connected: true, score: score, wordsFound: wordsFound,
      endsAtBonusMs: endsAtBonusMs, lastSeen: lastSeen,
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

Match _finished() => _active().copyWith(status: MatchStatus.finished);

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

  // Issue #64: a found word in a match used to only bloom the board tile and
  // fire a haptic, with none of single-player's ComboBanner praise line or
  // StreakConfetti burst. Trace the wheel to form the rack's one answer
  // ('IF') exactly the way a player would, and confirm the reused
  // celebration widgets actually react: no praise line before any find, the
  // praise line up once a word lands.
  testWidgets('finding a word in a match pops the found-word celebration',
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

    // The celebration widgets are mounted but silent before any find.
    expect(find.byType(ComboBanner), findsOneWidget);
    expect(find.byType(StreakConfetti), findsOneWidget);
    expect(find.text('Good!'), findsNothing);

    // Drive the same controller the wheel's onTouch/onEnd callbacks call
    // (mirrors game_page_test.dart's pattern for single-player), to trace
    // 'IF', the rack's only answer.
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MatchPage)));
    final controller = container.read(matchPlayControllerProvider.notifier);
    controller.touchLetter(0);
    controller.touchLetter(1);
    controller.endSelection(_rack(), const <String>{});
    await tester.pump();

    // A fresh local find pops the praise line (ComboBanner) up.
    expect(find.text('Good!'), findsOneWidget);
    expect(find.textContaining('Combo Streak'), findsOneWidget);
  });

  // Regression #57: Word Steal credits players.${uid}.wordsFound on the
  // caster WITHOUT adding the stolen word to the caster's own rack
  // foundWords (by design, server-side). The HUD's "You" word count must
  // therefore read the authoritative players[uid].wordsFound, not
  // rack.foundWords.length, or it undercounts right after a steal even
  // though the opponent's chip (and the win condition) already reflect the
  // true, higher value.
  testWidgets(
      "my HUD word count reflects players[uid].wordsFound, not "
      'rack.foundWords.length, after a steal inflates it', (tester) async {
    final remote = _FakeRemote();
    final afterSteal = _active().copyWith(
      players: {
        // I only ever found 1 word myself, but a steal bumped my
        // authoritative wordsFound to 3 without touching my rack.
        'me': _p('me', score: 7, wordsFound: 3),
        'opp': _p('opp', score: 3, wordsFound: 5),
      },
    );
    const rackAfterSteal = MatchRack(
      uid: 'me', letters: ['I', 'F'], letterKey: 'FI', rackSize: 2,
      answers: [PuzzleAnswer(word: 'IF', length: 2, definition: null)],
      answerCount: 1, foundWords: ['IF'], // length 1, deliberately stale
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchServiceProvider.overrideWithValue(remote),
        matchStreamProvider('m1')
            .overrideWith((ref) => Stream.value(afterSteal)),
        myRackStreamProvider('m1')
            .overrideWith((ref) => Stream.value(rackAfterSteal)),
        matchEventsStreamProvider('m1')
            .overrideWith((ref) => Stream.value(const <MatchEvent>[])),
        storeCatalogProvider.overrideWith((ref) async => const <StoreItem>[]),
      ],
      child: const MaterialApp(home: MatchPage(matchId: 'm1')),
    ));
    await tester.pump();
    await tester.pump();

    // My authoritative word count (3) must be on screen...
    expect(find.text('· 3'), findsOneWidget);
    // ...and the stale rack-derived count (1) must NOT be what "You" shows.
    expect(find.text('· 1'), findsNothing);
  });

  // The HUD countdown must track MY per-player deadline (endsAt + my banked
  // time_boost bonus), not the raw endsAt: a boosted player would otherwise
  // watch their timer expire early. With endsAt 90s away but a 1h bonus for
  // me, the timer must render in the over-an-hour "Xh YYm" form.
  testWidgets('HUD timer uses my boosted per-player deadline, not raw endsAt',
      (tester) async {
    final remote = _FakeRemote();
    final boosted = _active().copyWith(
      players: {
        'me': _p('me', score: 7, endsAtBonusMs: 3600000),
        'opp': _p('opp', score: 3),
      },
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchServiceProvider.overrideWithValue(remote),
        matchStreamProvider('m1').overrideWith((ref) => Stream.value(boosted)),
        myRackStreamProvider('m1').overrideWith((ref) => Stream.value(_rack())),
        matchEventsStreamProvider('m1')
            .overrideWith((ref) => Stream.value(const <MatchEvent>[])),
        storeCatalogProvider.overrideWith((ref) async => const <StoreItem>[]),
      ],
      child: const MaterialApp(home: MatchPage(matchId: 'm1')),
    ));
    await tester.pump();
    await tester.pump();

    // Raw endsAt is ~90s out (would render "1:29" style); my deadline is
    // ~1h 1m out, so the over-an-hour format must be on screen.
    expect(find.textContaining('h '), findsOneWidget);
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

  // Issue #76: the boundary poke must be driven by the matchStreamProvider
  // listener, not by build(). Deliver a match that is NOT past any boundary
  // as the first emission (so the initial build sees nothing due), then push
  // a second emission, past the start boundary, on the same broadcast
  // stream. A plain rebuild (no new stream value) must not poke settle on
  // its own; the poke must land only once the new value with the due
  // boundary is delivered.
  testWidgets(
      'a boundary that becomes due on a new match value pokes settle via the '
      'stream listener, not on every build', (tester) async {
    final remote = _FakeRemote();
    final now = DateTime.now().millisecondsSinceEpoch;
    final matches = StreamController<Match>.broadcast();
    addTearDown(matches.close);
    final notYetDue = _active().copyWith(
      status: MatchStatus.countdown,
      startedAt: now + 60000,
      endsAt: now + 120000,
    );
    final pastStart = _active().copyWith(
      status: MatchStatus.countdown,
      startedAt: now - 1000,
      endsAt: now + 120000,
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchServiceProvider.overrideWithValue(remote),
        matchStreamProvider('m1').overrideWith((ref) => matches.stream),
        myRackStreamProvider('m1').overrideWith((ref) => Stream.value(_rack())),
        matchEventsStreamProvider('m1')
            .overrideWith((ref) => Stream.value(const <MatchEvent>[])),
        storeCatalogProvider.overrideWith((ref) async => const <StoreItem>[]),
      ],
      child: const MaterialApp(home: MatchPage(matchId: 'm1')),
    ));
    matches.add(notYetDue);
    await tester.pump();
    await tester.pump();

    // Build alone (repeated pumps, no new match value) must not poke settle:
    // neither boundary is due yet on the current value.
    await tester.pump();
    await tester.pump();
    expect(remote.settled, isEmpty);

    // A new match value that is now past the start boundary arrives: the
    // listener (not build) is what pokes settle here.
    matches.add(pastStart);
    await tester.pump();
    await tester.pump();
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

  // Issue #58: respondChallenge writes an ASYNC match straight to
  // status:active with no lobby/countdown, so on entry neither settle
  // boundary above is due (status isn't countdown, and endsAt is hours out).
  // Before the fix nothing ever poked settle, so ServerClock stayed at its
  // never-synced Duration.zero offset for the whole resumed session. The
  // match page must poke the settling GET once on load anyway, purely to
  // pull down serverNow, even with both boundaries not due.
  testWidgets(
      'entering a freshly-loaded async match syncs the clock even though no '
      'boundary is due', (tester) async {
    final remote = _FakeRemote();
    final now = DateTime.now().millisecondsSinceEpoch;
    // Mirrors an async challenge on entry: active, started long ago, ends
    // hours from now. Neither the start nor the end boundary is due.
    final asyncNoBoundaryDue = _asyncActive().copyWith(
      startedAt: now - 60000,
      endsAt: now + const Duration(hours: 6).inMilliseconds,
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchServiceProvider.overrideWithValue(remote),
        matchStreamProvider('m1')
            .overrideWith((ref) => Stream.value(asyncNoBoundaryDue)),
        myRackStreamProvider('m1').overrideWith((ref) => Stream.value(_rack())),
        matchEventsStreamProvider('m1')
            .overrideWith((ref) => Stream.value(const <MatchEvent>[])),
        storeCatalogProvider.overrideWith((ref) async => const <StoreItem>[]),
      ],
      child: const MaterialApp(home: MatchPage(matchId: 'm1')),
    ));
    await tester.pump();
    await tester.pump();

    // The dedicated load-time sync fired exactly once, even with no
    // boundary due.
    expect(remote.settled, <String>['m1']);

    // Not a spam loop: further ticks must not poke settle again just
    // because the clock sync is (in this fake) never actually observed as
    // synced.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
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

  // Issue #46: the server only ever clears `connected` on leaving a LOBBY /
  // COUNTDOWN match, never during ACTIVE play, so a dropped opponent's dot
  // used to stay green forever. The HUD dot must be driven off `lastSeen`
  // freshness instead: a stale `lastSeen` greys the dot even though the raw
  // `connected` flag (set by `_p`) is still true.
  testWidgets(
      'opponent HUD dot greys out once lastSeen is older than the presence '
      'staleness threshold, even though connected is still true',
      (tester) async {
    final remote = _FakeRemote();
    final staleOpponent = _active().copyWith(
      players: {
        'me': _p('me', score: 7),
        'opp': _p(
          'opp',
          score: 3,
          lastSeen: DateTime.now().millisecondsSinceEpoch -
              kOpponentPresenceStaleAfterMs -
              5000,
        ),
      },
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchServiceProvider.overrideWithValue(remote),
        matchStreamProvider('m1')
            .overrideWith((ref) => Stream.value(staleOpponent)),
        myRackStreamProvider('m1').overrideWith((ref) => Stream.value(_rack())),
        matchEventsStreamProvider('m1')
            .overrideWith((ref) => Stream.value(const <MatchEvent>[])),
        storeCatalogProvider.overrideWith((ref) async => const <StoreItem>[]),
      ],
      child: const MaterialApp(home: MatchPage(matchId: 'm1')),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
    expect(find.byIcon(Icons.circle), findsNothing);
  });

  testWidgets(
      'opponent HUD dot stays green while lastSeen is fresh',
      (tester) async {
    final remote = _FakeRemote();
    final freshOpponent = _active().copyWith(
      players: {
        'me': _p('me', score: 7),
        'opp': _p(
          'opp',
          score: 3,
          lastSeen: DateTime.now().millisecondsSinceEpoch - 1000,
        ),
      },
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchServiceProvider.overrideWithValue(remote),
        matchStreamProvider('m1')
            .overrideWith((ref) => Stream.value(freshOpponent)),
        myRackStreamProvider('m1').overrideWith((ref) => Stream.value(_rack())),
        matchEventsStreamProvider('m1')
            .overrideWith((ref) => Stream.value(const <MatchEvent>[])),
        storeCatalogProvider.overrideWith((ref) async => const <StoreItem>[]),
      ],
      child: const MaterialApp(home: MatchPage(matchId: 'm1')),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.byIcon(Icons.circle), findsOneWidget);
    expect(find.byIcon(Icons.circle_outlined), findsNothing);
  });

  // Issue #46 review follow-up: the two tests above only assert the dot at a
  // fixed initial timestamp, which the original (broken) implementation
  // could also pass, since the presence bool was computed once at build
  // time from whatever lastSeen already was. The actual bug only shows up
  // when BOTH players go idle: nothing submits, nothing casts, the match
  // stream never re-emits, and the page's own gate never moves (a 6h endsAt
  // keeps the match playable throughout, and `_onTick`'s gate arithmetic
  // runs on the raw device clock, never the injected one below), so nothing
  // above the opponent chip would ever trigger a rebuild. `lastSeen` is
  // fixed for the whole test; a `ServerClock` override lets the test move
  // "now" forward the same way a real server-clock sync would, without a
  // literal 90+ second sleep. The dot must flip to grey on its own, from the
  // opponent chip's own tick alone, proving it does not freeze at whatever
  // it last read on the page's last rebuild.
  testWidgets(
      'opponent HUD dot goes stale from a live clock tick, with no other '
      'state change',
      (tester) async {
    final remote = _FakeRemote();
    final clock = ServerClock();
    final now = DateTime.now().millisecondsSinceEpoch;
    final idleMatch = _active().copyWith(
      // Far beyond the clock jump below, so the match never times out and
      // the page's own gate-driven rebuild never fires.
      endsAt: now + const Duration(hours: 6).inMilliseconds,
      players: {
        'me': _p('me', score: 7),
        'opp': _p('opp', score: 3, lastSeen: now - 1000),
      },
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchServiceProvider.overrideWithValue(remote),
        serverClockProvider.overrideWithValue(clock),
        matchStreamProvider('m1')
            .overrideWith((ref) => Stream.value(idleMatch)),
        myRackStreamProvider('m1').overrideWith((ref) => Stream.value(_rack())),
        matchEventsStreamProvider('m1')
            .overrideWith((ref) => Stream.value(const <MatchEvent>[])),
        storeCatalogProvider.overrideWith((ref) async => const <StoreItem>[]),
      ],
      child: const MaterialApp(home: MatchPage(matchId: 'm1')),
    ));
    await tester.pump();
    await tester.pump();

    // Starts green: lastSeen is 1s old.
    expect(find.byIcon(Icons.circle), findsOneWidget);
    expect(find.byIcon(Icons.circle_outlined), findsNothing);

    // Move the server clock (and only the server clock: the match doc, the
    // rack, and the events stream are untouched) well past the staleness
    // threshold, exactly as a real `serverNow` sync would. Then pump just
    // enough real-time-equivalent for the opponent chip's own 500ms ticker
    // (not the page's) to fire once and pick it up.
    clock.sync(now + kOpponentPresenceStaleAfterMs + 5000);
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
    expect(find.byIcon(Icons.circle), findsNothing);
  });

  // Issue #47: the playability gate (and the settle-boundary pokes) must read
  // the SAME server-corrected clock the displayed timers already use, not the
  // raw device clock. Sync the server clock 5s ahead of the device: `startedAt`
  // sits 2s out by the raw device clock (still "counting down" under the old,
  // buggy device-clock gate) but is already 3s in the past by the
  // server-corrected clock the fix must use.
  testWidgets(
      'the countdown gate opens the board on the server clock, not the '
      'device clock',
      (tester) async {
    final remote = _FakeRemote();
    final clock = ServerClock();
    final now = DateTime.now().millisecondsSinceEpoch;
    clock.sync(now + 5000); // offset becomes +5s (serverNow - deviceNow)
    final counting = _active().copyWith(
      status: MatchStatus.countdown,
      startedAt: now + 2000,
      endsAt: now + 90000,
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchServiceProvider.overrideWithValue(remote),
        serverClockProvider.overrideWithValue(clock),
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

    // The server clock has already crossed startedAt, so the board must be
    // open on the very first build: no "Get ready" hold, and the start
    // boundary already poked the settling GET.
    expect(find.textContaining('Get ready'), findsNothing);
    expect(find.text('I'), findsWidgets);
    expect(remote.settled, <String>['m1']);
  });

  // The other half: a device clock AHEAD of the server must not lock the
  // board (or poke the end boundary) before the server clock says time is up.
  testWidgets(
      'the expiry gate holds the board open on the server clock, not a '
      'device clock that has already run past endsAt',
      (tester) async {
    final remote = _FakeRemote();
    final clock = ServerClock();
    final now = DateTime.now().millisecondsSinceEpoch;
    clock.sync(now - 5000); // offset becomes -5s: server is BEHIND the device
    final active = _active().copyWith(
      startedAt: now - 90000,
      // 2s in the past by the raw device clock (would already read "Time's
      // up" under the old device-clock gate), but still 3s in the FUTURE by
      // the server-corrected clock.
      endsAt: now - 2000,
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchServiceProvider.overrideWithValue(remote),
        serverClockProvider.overrideWithValue(clock),
        matchStreamProvider('m1').overrideWith((ref) => Stream.value(active)),
        myRackStreamProvider('m1').overrideWith((ref) => Stream.value(_rack())),
        matchEventsStreamProvider('m1')
            .overrideWith((ref) => Stream.value(const <MatchEvent>[])),
        storeCatalogProvider.overrideWith((ref) async => const <StoreItem>[]),
      ],
      child: const MaterialApp(home: MatchPage(matchId: 'm1')),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining("Time's up"), findsNothing);
    expect(find.text('I'), findsWidgets); // the board is still up
    expect(remote.settled, isEmpty); // the end boundary has not poked yet
  });

  // Regression for #37 + #38: _leaveMatch navigates home before the forfeit is
  // recorded, so the match page (and its `ref`) are torn down before the
  // finished transition could ever be observed. Without capturing a
  // longer-lived container, the Resume list, the "Play with friends" badge, and
  // history would stay stale until a manual refresh. #38 additionally routes
  // the leave through the durable offline queue (instead of a bare
  // fire-and-forget HTTP call) so it survives an offline exit. Drive a real
  // forfeit through a minimal GoRouter (home is a stub that watches both
  // providers, so a refresh is directly observable). The gated repo lets us
  // assert that the durable row is written up front, that home is already up
  // (navigation never waits on the write), and that the two surfaces refresh
  // only once the enqueue future completes, not before.
  testWidgets(
      'forfeiting a live match queues a durable leave and refreshes resume + history',
      (tester) async {
    final remote = _FakeRemote();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final leaveRepo = _GatedLeaveRepo(db);
    var activeMatchesCalls = 0;
    var matchHistoryCalls = 0;

    final router = GoRouter(
      initialLocation: '/match',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const _HomeStub()),
        GoRoute(
          path: '/match',
          builder: (_, __) => const MatchPage(matchId: 'm1'),
        ),
      ],
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchServiceProvider.overrideWithValue(remote),
        matchLeaveRepositoryProvider.overrideWithValue(leaveRepo),
        matchStreamProvider('m1').overrideWith((ref) => Stream.value(_active())),
        myRackStreamProvider('m1').overrideWith((ref) => Stream.value(_rack())),
        matchEventsStreamProvider('m1')
            .overrideWith((ref) => Stream.value(const <MatchEvent>[])),
        storeCatalogProvider.overrideWith((ref) async => const <StoreItem>[]),
        activeMatchesProvider.overrideWith((ref) async {
          activeMatchesCalls++;
          return const <ActiveMatch>[];
        }),
        matchHistoryProvider.overrideWith((ref) async {
          matchHistoryCalls++;
          return const <MatchHistoryEntry>[];
        }),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.pump();

    // Tap the live-match forfeit flag, then confirm.
    await tester.tap(find.bySemanticsLabel('Leave match'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forfeit'));
    await tester.pumpAndSettle();

    // Home is up (navigation does not wait on the write), the durable leave row
    // is already queued for the leave endpoint (routed through the offline
    // engine, not fired straight at the remote), and the stub's first build has
    // read each provider exactly once.
    expect(find.text('home'), findsOneWidget);
    expect(remote.left, isEmpty); // no bare fire-and-forget call anymore
    final queued = await db.pendingMutationsDao.due(
      DateTime.now().millisecondsSinceEpoch,
    );
    expect(queued, hasLength(1));
    expect(queued.single.endpoint, '/matches/m1/leave');
    expect(queued.single.kind, kMatchLeaveKind);
    expect(queued.single.idempotencyKey, 'leave:m1');
    expect(activeMatchesCalls, 1);
    expect(matchHistoryCalls, 1);

    // The enqueue future has NOT completed yet: no refresh fired early.
    expect(activeMatchesCalls, 1);
    expect(matchHistoryCalls, 1);

    // Let the enqueue future resolve.
    leaveRepo.gate.complete();
    await tester.pumpAndSettle();

    // Both surfaces refreshed once the queue write settled, so the Resume list /
    // badge / history drop the forfeited match without a manual pull-to-refresh.
    expect(activeMatchesCalls, 2);
    expect(matchHistoryCalls, 2);
  });

  // Issue #52: `MatchRemote.powerup` only maps a 402 to a result; every other
  // error (a 409 "nothing to steal", an offline DioException, ...) is
  // rethrown. Before the fix, `_firePowerup` had no try/catch around the
  // await, so that rethrow propagated out uncaught: the optimistic inventory
  // decrement it made up front was never reversed and no "could not fire"
  // feedback ever showed. Firing word_steal here stands in for the common
  // real trigger (casting before the opponent has any words).
  testWidgets(
      'a powerup fire whose server call throws refunds the optimistic '
      'inventory decrement and does not throw uncaught', (tester) async {
    final remote = _FakeRemote()
      ..powerupDelay = const Duration(milliseconds: 50)
      ..powerupError = DioException(
        requestOptions: RequestOptions(path: '/matches/m1/powerup'),
        response: Response(
          requestOptions: RequestOptions(path: '/matches/m1/powerup'),
          statusCode: 409,
        ),
        type: DioExceptionType.badResponse,
      );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchServiceProvider.overrideWithValue(remote),
        matchStreamProvider('m1').overrideWith((ref) => Stream.value(_active())),
        myRackStreamProvider('m1').overrideWith((ref) => Stream.value(_rack())),
        matchEventsStreamProvider('m1')
            .overrideWith((ref) => Stream.value(const <MatchEvent>[])),
        storeCatalogProvider.overrideWith((ref) async => const <StoreItem>[]),
        inventoryControllerProvider.overrideWith(_FakeInventoryController.new),
      ],
      child: const MaterialApp(home: MatchPage(matchId: 'm1')),
    ));
    await tester.pump(); // streams emit
    await tester.pump(); // rack sync + rebuild

    final container =
        ProviderScope.containerOf(tester.element(find.byType(MatchPage)));
    expect(container.read(inventoryControllerProvider).value, {'word_steal': 1});

    // Open the offense wheel and drag the word_steal slot past the fire
    // threshold, mirroring the real cast gesture.
    await tester.tap(find.bySemanticsLabel('Offense powerups'));
    await tester.pump();
    final slot = find.byKey(const ValueKey('powerup_slot_word_steal'));
    expect(slot, findsOneWidget);

    await tester.drag(slot, const Offset(0, -100)); // past fireThreshold (64)
    await tester.pump(); // _firePowerup runs synchronously up to the await

    // The optimistic decrement landed immediately, before the server ever
    // answered.
    expect(container.read(inventoryControllerProvider).value, {'word_steal': 0});

    // Let the (throwing) await resolve and the catch block's refund run.
    // pumpAndSettle also proves nothing escapes as an uncaught exception:
    // flutter_test fails the test on any Zone error surfaced during pumping.
    await tester.pumpAndSettle();

    expect(container.read(inventoryControllerProvider).value, {'word_steal': 1});

    // Snack coverage note: `showPondSnack` renders through `ScaffoldMessenger`
    // inside `MaterialApp`'s default scaffold messenger, which this minimal
    // host does exercise, but the snack text itself is not asserted here
    // (the invariant this test pins down is the refund + no uncaught throw).
  });

  // Issue #59: `ref.listen(matchStreamProvider...)` only navigates to the
  // result page on a NEW `status == finished` emission. `matchStreamProvider`
  // has no autoDispose, so a match that already finished (deep link, back-nav
  // from the result screen, or a stale Resume tap) can leave a FINISHED value
  // cached on the stream for the very next mount to read straight away, with
  // no listener transition ever firing. Entering the page directly on a match
  // that is already finished must redirect to the result route on its own,
  // and must never paint the interactive letter wheel even for one frame.
  testWidgets(
      'entering match_page with a cached finished match redirects to the '
      'result route and never renders the interactive letter wheel',
      (tester) async {
    final remote = _FakeRemote();
    final router = GoRouter(
      initialLocation: '/multiplayer/match/m1',
      routes: [
        GoRoute(
          path: '/multiplayer/match/:id',
          builder: (_, state) =>
              MatchPage(matchId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/multiplayer/result/:id',
          builder: (_, __) => const Text('result screen'),
        ),
      ],
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchServiceProvider.overrideWithValue(remote),
        matchStreamProvider('m1')
            .overrideWith((ref) => Stream.value(_finished())),
        myRackStreamProvider('m1').overrideWith((ref) => Stream.value(_rack())),
        matchEventsStreamProvider('m1')
            .overrideWith((ref) => Stream.value(const <MatchEvent>[])),
        storeCatalogProvider.overrideWith((ref) async => const <StoreItem>[]),
        activeMatchesProvider
            .overrideWith((ref) async => const <ActiveMatch>[]),
        matchHistoryProvider
            .overrideWith((ref) async => const <MatchHistoryEntry>[]),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    expect(find.text('result screen'), findsOneWidget);
    expect(find.byType(LetterWheel), findsNothing);
    expect(find.bySemanticsLabel('Shuffle'), findsNothing);
  });

  // Issue #62: lobby_page navigates home when a match is cancelled
  // (lobby_page.dart:33-35), but match_page's status listener used to react
  // only to `finished`, and `_content` fell through to the permanent
  // "Time's up" interlude for a cancelled match (countingDownAt false,
  // playable false, status != finished true), with no way out but the OS
  // back button. A countdown-phase cancellation (e.g. the opponent
  // force-leaves before the match starts) must instead navigate home with a
  // notice, the same way the lobby does.
  testWidgets(
      'a match cancelled during the countdown navigates home with a notice, '
      'never sticking on "Time\'s up"', (tester) async {
    final remote = _FakeRemote();
    final now = DateTime.now().millisecondsSinceEpoch;
    final matches = StreamController<Match>.broadcast();
    addTearDown(matches.close);
    final counting = _active().copyWith(
      status: MatchStatus.countdown,
      startedAt: now + 30000,
      endsAt: now + 120000,
    );

    final router = GoRouter(
      initialLocation: '/multiplayer/match/m1',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const _HomeStub()),
        GoRoute(
          path: '/multiplayer/match/:id',
          builder: (_, state) =>
              MatchPage(matchId: state.pathParameters['id']!),
        ),
      ],
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchServiceProvider.overrideWithValue(remote),
        matchStreamProvider('m1').overrideWith((ref) => matches.stream),
        myRackStreamProvider('m1').overrideWith((ref) => Stream.value(_rack())),
        matchEventsStreamProvider('m1')
            .overrideWith((ref) => Stream.value(const <MatchEvent>[])),
        storeCatalogProvider.overrideWith((ref) async => const <StoreItem>[]),
        activeMatchesProvider
            .overrideWith((ref) async => const <ActiveMatch>[]),
        matchHistoryProvider
            .overrideWith((ref) async => const <MatchHistoryEntry>[]),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    matches.add(counting);
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Get ready'), findsOneWidget);

    // The opponent force-leaves during the countdown: the server cancels
    // the match.
    matches.add(counting.copyWith(status: MatchStatus.cancelled));
    await tester.pump(); // the listener navigates and shows the snack
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('home'), findsOneWidget);
    expect(find.text('Match cancelled'), findsOneWidget);
    expect(find.textContaining("Time's up"), findsNothing);
  });

  // Issue #60 (client part): a server rack-draw failure during join can leave
  // a committed participant with no `racks/{uid}` doc at all. `watchMyRack`
  // then emits null (the doc does not exist) and stays there forever - before
  // the fix, `_content` treated `rack == null` the same as still-loading and
  // spun endlessly, with no retry. A brief null window right after join is
  // normal, so the page must hold a plain spinner until the grace window
  // (`kRackMissingGrace`) elapses; only past that window does it give up and
  // show `MatchLoadError` with a Retry.
  testWidgets(
      'a rack stream that stays null past the grace period shows '
      'MatchLoadError with a Retry, not a spinner', (tester) async {
    final remote = _FakeRemote();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchServiceProvider.overrideWithValue(remote),
        matchStreamProvider('m1').overrideWith((ref) => Stream.value(_active())),
        // The racks/{uid} doc never exists: the stream settles on null and
        // never emits again, mirroring a failed server rack draw.
        myRackStreamProvider('m1')
            .overrideWith((ref) => Stream<MatchRack?>.value(null)),
        matchEventsStreamProvider('m1')
            .overrideWith((ref) => Stream.value(const <MatchEvent>[])),
        storeCatalogProvider.overrideWith((ref) async => const <StoreItem>[]),
      ],
      child: const MaterialApp(home: MatchPage(matchId: 'm1')),
    ));
    await tester.pump(); // streams emit
    await tester.pump(); // rebuild

    // Still inside the grace window: a plain spinner, no error yet.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Could not reach the match'), findsNothing);

    // Advance past the grace window with the rack still null.
    await tester.pump(kRackMissingGrace + const Duration(seconds: 1));

    expect(find.text('Could not reach the match'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  // Issue #61: the board's Firestore listeners (found words / score /
  // effects) go silent while offline, but nothing else on the page notices,
  // so the board looks live while it is actually stale. The page must watch
  // isOnlineProvider directly and surface a banner while it reads false.
  testWidgets('an offline isOnlineProvider shows the reconnecting banner',
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
        isOnlineProvider.overrideWith((ref) => Stream.value(false)),
      ],
      child: const MaterialApp(home: MatchPage(matchId: 'm1')),
    ));
    await tester.pump(); // streams emit
    await tester.pump(); // rebuild

    expect(find.textContaining('Reconnecting'), findsOneWidget);
  });

  testWidgets('an online isOnlineProvider hides the reconnecting banner',
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
        isOnlineProvider.overrideWith((ref) => Stream.value(true)),
      ],
      child: const MaterialApp(home: MatchPage(matchId: 'm1')),
    ));
    await tester.pump(); // streams emit
    await tester.pump(); // rebuild

    expect(find.textContaining('Reconnecting'), findsNothing);
  });

  // Issue #65: the most emotional beats (word found, win/lose, opponent
  // scored) had no SFX at all. Trace the wheel to form the rack's one
  // answer, exactly like the #64 celebration test, and confirm the
  // word-found cue fires through the same mute-aware AudioService the
  // powerup calls already use.
  testWidgets('finding a word in a match plays the word-found SFX',
      (tester) async {
    final remote = _FakeRemote();
    final audio = _FakeAudio();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchServiceProvider.overrideWithValue(remote),
        audioServiceProvider.overrideWithValue(audio),
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

    expect(audio.played, isEmpty);

    final container =
        ProviderScope.containerOf(tester.element(find.byType(MatchPage)));
    final controller = container.read(matchPlayControllerProvider.notifier);
    controller.touchLetter(0);
    controller.touchLetter(1);
    controller.endSelection(_rack(), const <String>{});
    await tester.pump();

    expect(audio.played, contains(SfxKeys.wordFound));
  });

  // Issue #65: on the finish transition, the win/lose cue must agree with
  // MatchResult.fromFinishedMatch's outcome. `_finished()`'s winner is unset,
  // so the outcome falls back to a score comparison: my 7 beats the
  // opponent's 3, so this must be a win, cued exactly once.
  testWidgets(
      'a match finishing with me ahead on score plays the match-won SFX',
      (tester) async {
    final remote = _FakeRemote();
    final audio = _FakeAudio();
    final router = GoRouter(
      initialLocation: '/multiplayer/match/m1',
      routes: [
        GoRoute(
          path: '/multiplayer/match/:id',
          builder: (_, state) =>
              MatchPage(matchId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/multiplayer/result/:id',
          builder: (_, __) => const Text('result screen'),
        ),
      ],
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchServiceProvider.overrideWithValue(remote),
        audioServiceProvider.overrideWithValue(audio),
        matchStreamProvider('m1')
            .overrideWith((ref) => Stream.value(_finished())),
        myRackStreamProvider('m1').overrideWith((ref) => Stream.value(_rack())),
        matchEventsStreamProvider('m1')
            .overrideWith((ref) => Stream.value(const <MatchEvent>[])),
        storeCatalogProvider.overrideWith((ref) async => const <StoreItem>[]),
        activeMatchesProvider
            .overrideWith((ref) async => const <ActiveMatch>[]),
        matchHistoryProvider
            .overrideWith((ref) async => const <MatchHistoryEntry>[]),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    expect(find.text('result screen'), findsOneWidget);
    expect(audio.played, [SfxKeys.matchWon]);
  });

  // Issue #65: the opponent's authoritative wordsFound going up (a local
  // find on their side, or a word steal credited to them) must cue the
  // opponent-scored SFX, not just my own finds.
  testWidgets('the opponent finding a word plays the opponent-scored SFX',
      (tester) async {
    final remote = _FakeRemote();
    final audio = _FakeAudio();
    final matches = StreamController<Match>.broadcast();
    addTearDown(matches.close);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchServiceProvider.overrideWithValue(remote),
        audioServiceProvider.overrideWithValue(audio),
        matchStreamProvider('m1').overrideWith((ref) => matches.stream),
        myRackStreamProvider('m1').overrideWith((ref) => Stream.value(_rack())),
        matchEventsStreamProvider('m1')
            .overrideWith((ref) => Stream.value(const <MatchEvent>[])),
        storeCatalogProvider.overrideWith((ref) async => const <StoreItem>[]),
      ],
      child: const MaterialApp(home: MatchPage(matchId: 'm1')),
    ));
    await tester.pump();
    matches.add(_active());
    await tester.pump();
    await tester.pump();

    expect(audio.played, isEmpty);

    matches.add(_active().copyWith(
      players: {
        'me': _p('me', score: 7),
        'opp': _p('opp', score: 3, wordsFound: 1),
      },
    ));
    await tester.pump();

    expect(audio.played, [SfxKeys.opponentScored]);
  });
}

/// Seeds the inventory with one owned `word_steal` so the #52 fire-throws
/// test can drag a slot that is actually owned (an unowned slot ignores pan
/// gestures entirely, see `PowerupWheelSlot`).
class _FakeInventoryController extends InventoryController {
  @override
  Future<Map<String, int>> build() async => {'word_steal': 1};
}

/// A [MatchLeaveRepository] whose `enqueueLeave` writes the durable row up front
/// (so the queue is observable immediately) but then holds its returned future
/// on [gate], so a test can assert what happens BEFORE vs AFTER the enqueue
/// future completes (the point at which `_leaveMatch` invalidates the resume
/// surfaces).
class _GatedLeaveRepo extends MatchLeaveRepository {
  _GatedLeaveRepo(super.db);

  final Completer<void> gate = Completer<void>();

  @override
  Future<void> enqueueLeave(String matchId) async {
    await super.enqueueLeave(matchId);
    await gate.future;
  }
}

/// Stands in for the real home route: just enough to prove that invalidating
/// [activeMatchesProvider] / [matchHistoryProvider] through a captured
/// container actually reaches a still-mounted watcher after this page's own
/// `ref` (the match page's) is gone.
class _HomeStub extends ConsumerWidget {
  const _HomeStub();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(activeMatchesProvider);
    ref.watch(matchHistoryProvider);
    return const Text('home');
  }
}
