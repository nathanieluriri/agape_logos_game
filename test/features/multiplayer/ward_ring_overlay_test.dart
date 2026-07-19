import 'package:agape_logos_game/core/design/tokens/durations.dart';
import 'package:agape_logos_game/features/multiplayer/presentation/widgets/ward_ring_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Finder paintFinder() => find.descendant(
    of: find.byType(WardRingOverlay),
    matching: find.byType(CustomPaint),
  );

  // The base ring and the deflect echo are now two INDEPENDENT paint layers
  // (a Stack: [base, if (pinging) echo]), so a single CustomPaint lookup no
  // longer works while a ping is live. `paints` returns them in tree order:
  // index 0 is always the base ring; index 1 (when present) is the echo.
  List<CustomPaint> paints(WidgetTester tester) =>
      tester.widgetList<CustomPaint>(paintFinder()).toList();

  double sweepValue(WidgetTester tester) =>
      (paints(tester).first.painter as dynamic).sweep as double;

  double pingValue(WidgetTester tester) =>
      (paints(tester).last.painter as dynamic).ping as double;

  testWidgets(
    'ring draws itself in on the rising edge and drops itself at wardUntil',
    (tester) async {
      var current = DateTime.now();
      final until = current.add(const Duration(seconds: 2));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WardRingOverlay(
              warded: true, wardUntil: until, now: () => current,
            ),
          ),
        ),
      );

      // Mid draw-in: strictly between 0 and 1, not merely "some paint
      // exists" - guards the exact regression class this task's plan
      // flagged (a TweenAnimationBuilder element reused across branch flips
      // settling immediately at its already-reached target instead of
      // actually animating).
      await tester.pump(const Duration(milliseconds: 200));
      expect(paintFinder(), findsWidgets);
      final sweepAt200ms = sweepValue(tester);
      expect(sweepAt200ms, greaterThan(0.0));
      expect(sweepAt200ms, lessThan(1.0));

      // Settles fully drawn once effectLand has elapsed.
      await tester.pump(AppDurations.effectLand);
      expect(sweepValue(tester), 1.0);

      await tester.pumpAndSettle();
      expect(paintFinder(), findsWidgets);

      // The one-shot expiry timer fires and the ring leaves (after its fade).
      current = until.add(const Duration(milliseconds: 1));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(paintFinder(), findsNothing);
    },
  );

  testWidgets('nothing renders while not warded', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WardRingOverlay(
            warded: false, wardUntil: null, now: DateTime.now,
          ),
        ),
      ),
    );
    expect(paintFinder(), findsNothing);
  });

  testWidgets(
    'a deflect ping pulses an echo ring mid-flight, and a second, later '
    'ping tick re-runs it rather than staying pinned',
    (tester) async {
      final until = DateTime.now().add(const Duration(seconds: 10));
      Widget host(int tick) => MaterialApp(
        home: Scaffold(
          body: WardRingOverlay(
            warded: true, wardUntil: until, now: DateTime.now, pingTick: tick,
          ),
        ),
      );

      await tester.pumpWidget(host(0));
      await tester.pumpAndSettle(); // settle the draw-in; sweep rests at 1.

      // First ping.
      await tester.pumpWidget(host(1));
      await tester.pump(const Duration(milliseconds: 150));
      expect(paints(tester).length, 2); // base + echo.
      final pingAt150ms = pingValue(tester);
      expect(pingAt150ms, greaterThan(0.0));
      expect(pingAt150ms, lessThan(1.0));

      // Let the first ping's window fully elapse and clear.
      await tester.pump(AppDurations.effectExpire);
      await tester.pumpAndSettle();
      expect(paints(tester).length, 1); // echo layer gone.

      // A second, later ping tick must re-run the pulse from scratch, not
      // stay pinned at whatever the first ping's (now-disposed) element
      // last held - the same reused-element bug class the draw-in/fade-out
      // phase keys guard against, applied to the ping's own key.
      await tester.pumpWidget(host(2));
      await tester.pump(const Duration(milliseconds: 150));
      final pingAt150msSecond = pingValue(tester);
      expect(pingAt150msSecond, greaterThan(0.0));
      expect(pingAt150msSecond, lessThan(1.0));

      // Drain the remaining timers (the second ping's own clear, and the
      // ward's own far-off expiry) so the test does not end with anything
      // pending.
      await tester.pump(const Duration(seconds: 11));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'a ping that arrives mid-pulse of an earlier one restarts cleanly '
    "instead of the earlier one's stale clear cutting it short",
    (tester) async {
      final until = DateTime.now().add(const Duration(seconds: 10));
      Widget host(int tick) => MaterialApp(
        home: Scaffold(
          body: WardRingOverlay(
            warded: true, wardUntil: until, now: DateTime.now, pingTick: tick,
          ),
        ),
      );

      await tester.pumpWidget(host(0));
      await tester.pumpAndSettle();

      // First ping starts.
      await tester.pumpWidget(host(1));
      await tester.pump(const Duration(milliseconds: 100));
      expect(pingValue(tester), greaterThan(0.0));

      // Second ping arrives before the first one's delayed clear (which
      // would fire effectExpire after the FIRST ping started) has run.
      await tester.pumpWidget(host(2));
      await tester.pump(const Duration(milliseconds: 100));
      final midSecond = pingValue(tester);
      expect(midSecond, greaterThan(0.0));
      expect(midSecond, lessThan(1.0));

      // Advance past the moment the FIRST ping's stale delayed-clear would
      // fire (100ms + 100ms = 200ms since ping 1 started; effectExpire is
      // 400ms, so push on to 350ms since ping 1 started / 250ms since ping
      // 2 started), while still inside ping 2's own effectExpire window.
      // Without the generation counter, the stale callback would clear
      // `_pinging` here and the echo layer would disappear entirely (base
      // ring only, 1 CustomPaint) - a directly observable difference from
      // the fix.
      await tester.pump(const Duration(milliseconds: 250));
      expect(paints(tester).length, 2);
      final stillMidSecond = pingValue(tester);
      expect(stillMidSecond, greaterThan(0.0));
      expect(stillMidSecond, lessThan(1.0));

      // Drain the remaining timers so the test does not end with anything
      // pending.
      await tester.pump(const Duration(seconds: 11));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'the settled base ring stays byte-identical through a ping: no '
    're-draw once it ends',
    (tester) async {
      final until = DateTime.now().add(const Duration(seconds: 10));
      Widget host(int tick) => MaterialApp(
        home: Scaffold(
          body: WardRingOverlay(
            warded: true, wardUntil: until, now: DateTime.now, pingTick: tick,
          ),
        ),
      );

      await tester.pumpWidget(host(0));
      await tester.pumpAndSettle();
      expect(sweepValue(tester), 1.0);
      expect(paints(tester).length, 1); // settled base only, no echo.

      // Ping: the echo layers on top, the base is still there underneath.
      await tester.pumpWidget(host(1));
      await tester.pump(const Duration(milliseconds: 100));
      expect(paints(tester).length, 2);
      expect(sweepValue(tester), 1.0); // base untouched by the ping.

      // Push exactly to the end of the ping's own window - the instant the
      // echo clears - and check IMMEDIATELY, in the same pump, WITHOUT a
      // trailing pumpAndSettle: a pumpAndSettle here would silently fast
      // -forward through any accidental base re-animation and hide exactly
      // the defect this test exists to catch (reviewer-observed: sweep
      // drops to ~0.007 right after a ping ends, then spends 600ms visibly
      // redrawing before settling back to 1).
      await tester.pump(AppDurations.effectExpire);
      expect(sweepValue(tester), 1.0);
      expect(paints(tester).length, 1);

      // And it must STAY at 1, not just a coincidental single-frame read -
      // across a further pump that would have been mid-redraw under the bug
      // (the draw-in's effectLand window is 600ms).
      await tester.pump(const Duration(milliseconds: 300));
      expect(sweepValue(tester), 1.0);
      expect(paints(tester).length, 1);

      // Drain the ward's own far-off expiry timer.
      await tester.pump(const Duration(seconds: 11));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'reduced motion renders the static ring instantly, a ping tick shows '
    'no echo, and expiry drops the ring without a fade',
    (tester) async {
      var current = DateTime.now();
      final until = current.add(const Duration(seconds: 2));
      Widget host(int tick) => MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: Scaffold(
            body: WardRingOverlay(
              warded: true,
              wardUntil: until,
              now: () => current,
              pingTick: tick,
            ),
          ),
        ),
      );

      await tester.pumpWidget(host(0));
      // No TweenAnimationBuilder involved: the static ring is already at
      // its fully-drawn value on the very first frame, never mid-draw.
      expect(paints(tester).length, 1);
      expect(sweepValue(tester), 1.0);

      // A ping tick under reduced motion never sets `_pinging`
      // (didUpdateWidget gates it on `!reduceMotion`), so no echo layer
      // ever appears.
      await tester.pumpWidget(host(1));
      await tester.pump();
      expect(paints(tester).length, 1);

      // The one-shot expiry timer fires and drops the ring; under reduced
      // motion there is no TweenAnimationBuilder-driven fade - the flat
      // sweep flips straight to 0 rather than easing through it.
      current = until.add(const Duration(milliseconds: 1));
      await tester.pump(const Duration(seconds: 2));
      expect(sweepValue(tester), 0.0);

      // Past the (still unconditionally armed) fade-clear delay: gone.
      await tester.pump(const Duration(seconds: 1));
      expect(paintFinder(), findsNothing);
    },
  );
}
