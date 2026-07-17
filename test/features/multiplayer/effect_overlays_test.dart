import 'package:agape_logos_game/features/multiplayer/application/server_clock.dart';
import 'package:agape_logos_game/features/multiplayer/presentation/widgets/frozen_letter_overlay.dart';
import 'package:agape_logos_game/features/multiplayer/presentation/widgets/match_hud.dart';
import 'package:agape_logos_game/features/multiplayer/presentation/widgets/match_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('frozen overlay shows a frost icon per frozen slot', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: FrozenLetterOverlay(
          frozenSlots: {0, 2}, letterCount: 4, size: Size(260, 260),
        ),
      ),
    ));
    expect(find.byIcon(Icons.ac_unit_rounded), findsNWidgets(2));
  });

  testWidgets('frozen overlay renders nothing when no slots frozen',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: FrozenLetterOverlay(
          frozenSlots: {}, letterCount: 4, size: Size(260, 260),
        ),
      ),
    ));
    expect(find.byIcon(Icons.ac_unit_rounded), findsNothing);
  });

  testWidgets('a lapsed frost disc lingers to shatter, then leaves the tree',
      (tester) async {
    Widget overlay(Set<int> slots) => MaterialApp(
      home: Scaffold(
        body: FrozenLetterOverlay(
          frozenSlots: slots, letterCount: 4, size: const Size(260, 260),
        ),
      ),
    );
    await tester.pumpWidget(overlay(const {1}));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.ac_unit_rounded), findsOneWidget);

    // The slot thaws: the disc must still be on screen mid-shatter...
    await tester.pumpWidget(overlay(const {}));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byIcon(Icons.ac_unit_rounded), findsOneWidget);

    // ...and gone once the shatter window has fully elapsed.
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byIcon(Icons.ac_unit_rounded), findsNothing);
  });

  testWidgets('reduced motion drops a thawed disc immediately', (tester) async {
    Widget overlay(Set<int> slots) => MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: MaterialApp(
        home: Scaffold(
          body: FrozenLetterOverlay(
            frozenSlots: slots, letterCount: 4, size: const Size(260, 260),
          ),
        ),
      ),
    );
    await tester.pumpWidget(overlay(const {1}));
    expect(find.byIcon(Icons.ac_unit_rounded), findsOneWidget);
    await tester.pumpWidget(overlay(const {}));
    await tester.pump();
    expect(find.byIcon(Icons.ac_unit_rounded), findsNothing);
  });

  testWidgets('match timer formats remaining m:ss under an hour',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: MatchTimer(endsAt: 95000, nowMillis: 5000)),
    ));
    expect(find.text('1:30'), findsOneWidget);
  });

  testWidgets('match timer formats remaining h mm at/over an hour',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: MatchTimer(endsAt: 3700000 + 5000, nowMillis: 5000),
      ),
    ));
    expect(find.text('1h 01m'), findsOneWidget);
  });

  testWidgets(
    'MatchHud ticks against the server clock, not the raw device clock',
    (tester) async {
      // The device clock is (simulated) 5 minutes behind the server: sync()
      // records a positive offset, so ServerClock.now() reads ahead of the
      // real device DateTime.now().
      final skewedClock = ServerClock()
        ..sync(DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch);

      // endsAt is 30s in the FUTURE by the raw device clock, but already 4m30s
      // in the PAST once corrected for the server's skew ahead.
      final endsAt = DateTime.now().add(const Duration(seconds: 30));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchHud(
              myScore: 0,
              myWords: 0,
              opponentName: 'Opponent',
              opponentWords: 0,
              opponentConnected: true,
              endsAt: endsAt,
              onDictionary: () {},
              now: skewedClock.now,
            ),
          ),
        ),
      );

      // A device-clock-only render would still show ~0:30 remaining; the
      // server-corrected render must already show the countdown clamped at
      // zero, proving the effect lapsed on server time.
      expect(find.text('0:00'), findsOneWidget);
      expect(find.text('0:30'), findsNothing);
    },
  );
}
