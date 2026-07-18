import 'dart:async';

import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:agape_logos_game/features/auth/application/auth_providers.dart';
import 'package:agape_logos_game/features/auth/domain/auth_user.dart';
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
import 'package:agape_logos_game/features/puzzles/domain/puzzle.dart';
import 'package:agape_logos_game/features/social/application/social_providers.dart';
import 'package:agape_logos_game/features/social/domain/match_history_entry.dart';
import 'package:agape_logos_game/features/store/application/store_providers.dart';
import 'package:agape_logos_game/features/store/domain/store_item.dart';
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

MatchPlayer _p(
  String uid, {
  int score = 0,
  int endsAtBonusMs = 0,
  int lastSeen = 0,
}) =>
    MatchPlayer(
      uid: uid, displayName: uid, avatarId: 'a', isGuest: false, ready: true,
      connected: true, score: score, wordsFound: 0,
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
