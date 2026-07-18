import 'package:agape_logos_game/features/multiplayer/domain/match_player.dart';
import 'package:agape_logos_game/features/multiplayer/presentation/widgets/match_hud.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A minimal opponent record for tests that only care about `connected`
/// rendering, not the live `lastSeen` staleness ticking (see
/// match_page_test.dart for that behavior).
MatchPlayer _opp({bool connected = true}) => MatchPlayer(
  uid: 'opp', displayName: 'Opp', avatarId: 'a', isGuest: false, ready: true,
  connected: connected, score: 0, wordsFound: 0,
);

void main() {
  Widget host(Widget child, {double width = 320}) => MaterialApp(
        home: Scaffold(
          body: SizedBox(width: width, child: child),
        ),
      );

  testWidgets('lays out without overflow at 320dp with a long opponent name',
      (tester) async {
    await tester.pumpWidget(host(
      MatchHud(
        myScore: 128,
        myWords: 5,
        opponentName: 'A Really Long Opponent Display Name Here',
        opponentScore: 42,
        opponentWords: 3,
        opponent: _opp(),
        endsAt: DateTime.now().add(const Duration(minutes: 5)),
        onDictionary: () {},
      ),
    ));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('128'), findsOneWidget);
  });

  testWidgets(
      "opponent's live score renders in the opponent chip (regression #30)",
      (tester) async {
    await tester.pumpWidget(host(
      MatchHud(
        myScore: 5,
        myWords: 1,
        opponentName: 'Opp',
        opponentScore: 42,
        opponentWords: 3,
        opponent: _opp(),
        endsAt: DateTime.now().add(const Duration(minutes: 5)),
        onDictionary: () {},
      ),
    ));
    await tester.pump();

    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('forfeit affordance is hidden when onForfeit is null',
      (tester) async {
    await tester.pumpWidget(host(
      MatchHud(
        myScore: 1,
        myWords: 0,
        opponentName: 'Opp',
        opponentScore: 0,
        opponentWords: 0,
        opponent: _opp(connected: false),
        endsAt: DateTime.now().add(const Duration(minutes: 5)),
        onDictionary: () {},
      ),
    ));
    await tester.pump();

    expect(find.bySemanticsLabel('Forfeit match'), findsNothing);
  });

  testWidgets('forfeit affordance appears and fires onForfeit when provided',
      (tester) async {
    var fired = false;
    await tester.pumpWidget(host(
      MatchHud(
        myScore: 1,
        myWords: 0,
        opponentName: 'Opp',
        opponentScore: 0,
        opponentWords: 0,
        opponent: _opp(connected: false),
        endsAt: DateTime.now().add(const Duration(minutes: 5)),
        onDictionary: () {},
        onForfeit: () => fired = true,
      ),
    ));
    await tester.pump();

    expect(find.bySemanticsLabel('Forfeit match'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Forfeit match'));
    await tester.pump();
    expect(fired, isTrue);
  });

  testWidgets('dictionary button fires onDictionary', (tester) async {
    var fired = false;
    await tester.pumpWidget(host(
      MatchHud(
        myScore: 1,
        myWords: 0,
        opponentName: 'Opp',
        opponentScore: 0,
        opponentWords: 0,
        opponent: _opp(connected: false),
        endsAt: DateTime.now().add(const Duration(minutes: 5)),
        onDictionary: () => fired = true,
      ),
    ));
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('Dictionary'));
    await tester.pump();
    expect(fired, isTrue);
  });

  testWidgets('timer shows m:ss under 1h', (tester) async {
    await tester.pumpWidget(host(
      MatchHud(
        myScore: 1,
        myWords: 0,
        opponentName: 'Opp',
        opponentScore: 0,
        opponentWords: 0,
        opponent: _opp(connected: false),
        endsAt: DateTime.now().add(const Duration(minutes: 5, seconds: 59)),
        onDictionary: () {},
      ),
    ));
    await tester.pump();

    expect(find.textContaining(':'), findsWidgets);
    expect(find.textContaining('h '), findsNothing);
  });

  testWidgets('timer shows h mm at/over 1h', (tester) async {
    await tester.pumpWidget(host(
      MatchHud(
        myScore: 1,
        myWords: 0,
        opponentName: 'Opp',
        opponentScore: 0,
        opponentWords: 0,
        opponent: _opp(connected: false),
        endsAt:
            DateTime.now().add(const Duration(hours: 5, minutes: 47, seconds: 10)),
        onDictionary: () {},
      ),
    ));
    await tester.pump();

    expect(find.textContaining('h '), findsOneWidget);
  });

  testWidgets('double points shows the x2 badge on the score pip',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MatchHud(
          myScore: 10, myWords: 2,
          opponentName: 'O', opponentScore: 7, opponentWords: 1, opponent: _opp(),
          endsAt: DateTime.now().add(const Duration(minutes: 2)),
          onDictionary: () {},
          doublePoints: true,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('x2'), findsOneWidget);
  });

  testWidgets(
      'stacked double points still shows x2, never x4 (regression #55: '
      'the server only ever awards a flat 2x)', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MatchHud(
          myScore: 10, myWords: 2,
          opponentName: 'O', opponentScore: 7, opponentWords: 1, opponent: _opp(),
          endsAt: DateTime.now().add(const Duration(minutes: 2)),
          onDictionary: () {},
          doublePoints: true,
          doubleStacks: 2,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('x2'), findsOneWidget);
    expect(find.text('x4'), findsNothing);
  });

  testWidgets(
      'a score gain under a stacked double points still floats a x2 pop, '
      'never x4 (regression #55)', (tester) async {
    Widget hud(int score) => MaterialApp(
      home: Scaffold(
        body: MatchHud(
          myScore: score, myWords: 2,
          opponentName: 'O', opponentScore: 7, opponentWords: 1, opponent: _opp(),
          endsAt: DateTime.now().add(const Duration(minutes: 2)),
          onDictionary: () {},
          doublePoints: true,
          doubleStacks: 2,
        ),
      ),
    );
    await tester.pumpWidget(hud(10));
    await tester.pumpAndSettle();
    await tester.pumpWidget(hud(24));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('+14 x2'), findsOneWidget);
    expect(find.text('+14 x4'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('+14 x2'), findsNothing);
  });

  testWidgets(
      'double points badge scale-in actually animates (not a static '
      'AnimatedScale(scale: 1))', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MatchHud(
          myScore: 10, myWords: 2,
          opponentName: 'O', opponentScore: 7, opponentWords: 1, opponent: _opp(),
          endsAt: DateTime.now().add(const Duration(minutes: 2)),
          onDictionary: () {},
          doublePoints: true,
        ),
      ),
    ));

    final badgeFinder = find.descendant(
      of: find.byKey(const ValueKey('double-points-badge')),
      matching: find.byType(Transform),
    );
    // Read the matrix's raw diagonal entry, not Matrix4.getMaxScaleOnAxis():
    // that helper is a raster/texture-resolution utility that floors its
    // result at 1.0 (never reports "less resolution needed"), so it can't
    // distinguish an in-progress sub-1.0 scale-in from the settled value.
    double badgeScale() =>
        tester.widget<Transform>(badgeFinder).transform.storage[0];

    // Mounting IS activation (the badge only exists in the tree while
    // active), so the very first frame starts the tween. Probe partway
    // through AppDurations.fast (180ms): AppCurves.pop (easeOutBack) has
    // already overshot past the 1.0 end value by its true midpoint (90ms),
    // so 45ms is used instead to land solidly between the 0.6 start and the
    // 1.0 rest value while still being clearly mid-animation, not an
    // endpoint.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 45));
    final midScale = badgeScale();
    expect(midScale, greaterThan(0.6));
    expect(midScale, lessThan(1.0));

    await tester.pumpAndSettle();
    expect(badgeScale(), 1.0);
  });

  testWidgets('a score gain under double points floats a doubled pop',
      (tester) async {
    Widget hud(int score) => MaterialApp(
      home: Scaffold(
        body: MatchHud(
          myScore: score, myWords: 2,
          opponentName: 'O', opponentScore: 7, opponentWords: 1, opponent: _opp(),
          endsAt: DateTime.now().add(const Duration(minutes: 2)),
          onDictionary: () {},
          doublePoints: true,
        ),
      ),
    );
    await tester.pumpWidget(hud(10));
    await tester.pumpAndSettle();
    await tester.pumpWidget(hud(24));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('+14 x2'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('+14 x2'), findsNothing);
  });

  testWidgets(
      'opponent chip pulses when their word count increments (issue #68)',
      (tester) async {
    Widget hud(int opponentWords) => MaterialApp(
      home: Scaffold(
        body: MatchHud(
          myScore: 5, myWords: 1,
          opponentName: 'Opp', opponentScore: 42, opponentWords: opponentWords,
          opponent: _opp(),
          endsAt: DateTime.now().add(const Duration(minutes: 5)),
          onDictionary: () {},
        ),
      ),
    );

    await tester.pumpWidget(hud(3));
    await tester.pumpAndSettle();

    Transform wordsTransform() => tester.widget<Transform>(
      find.ancestor(
        of: find.text('· 3'),
        matching: find.byType(Transform),
      ).first,
    );
    Transform wordsTransformFor(String text) => tester.widget<Transform>(
      find.ancestor(
        of: find.text(text),
        matching: find.byType(Transform),
      ).first,
    );

    // Settled state: no pulse in flight, scale reads 1.0.
    expect(wordsTransform().transform.storage[0], 1.0);

    // The count increments: the chip should be mid-pulse (scaled above 1.0)
    // right after the update, then settle back to 1.0.
    await tester.pumpWidget(hud(4));
    await tester.pump();
    final midScale = wordsTransformFor('· 4').transform.storage[0];
    expect(midScale, greaterThan(1.0));

    await tester.pumpAndSettle();
    expect(wordsTransformFor('· 4').transform.storage[0], 1.0);
  });

  testWidgets(
      'opponent chip does not pulse when word count is unchanged (issue #68)',
      (tester) async {
    Widget hud(int myScore) => MaterialApp(
      home: Scaffold(
        body: MatchHud(
          myScore: myScore, myWords: 1,
          opponentName: 'Opp', opponentScore: 42, opponentWords: 3,
          opponent: _opp(),
          endsAt: DateTime.now().add(const Duration(minutes: 5)),
          onDictionary: () {},
        ),
      ),
    );

    await tester.pumpWidget(hud(5));
    await tester.pumpAndSettle();
    await tester.pumpWidget(hud(6));
    await tester.pump();

    final scale = tester
        .widget<Transform>(
          find
              .ancestor(
                of: find.text('· 3'),
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform
        .storage[0];
    expect(scale, 1.0);
  });
}
