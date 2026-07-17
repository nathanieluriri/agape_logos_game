import 'package:agape_logos_game/core/design/tokens/colors.dart';
import 'package:agape_logos_game/features/multiplayer/presentation/widgets/fog_shader_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('no fog widget when fogUntil is null', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FogShaderOverlay(fogUntil: null, now: DateTime.now),
        ),
      ),
    );
    // Scoped to the overlay's own subtree: MaterialApp/Navigator wraps every
    // routed page in its own IgnorePointer (route-transition gesture guard),
    // so an unscoped search would find that one too.
    final finder = find.descendant(
      of: find.byType(FogShaderOverlay),
      matching: find.byType(IgnorePointer),
    );
    expect(finder, findsOneWidget);
    // Nothing is painted: the child under IgnorePointer is a shrink box.
    final ignore = tester.widget<IgnorePointer>(finder);
    expect(ignore.ignoring, isTrue);
  });

  testWidgets('taps pass through the fog to a button beneath it', (
    tester,
  ) async {
    var tapped = false;
    final future = DateTime.now().add(const Duration(seconds: 8));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => tapped = true,
                ),
              ),
              Positioned.fill(
                child: FogShaderOverlay(fogUntil: future, now: DateTime.now),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byType(FogShaderOverlay), warnIfMissed: false);
    expect(tapped, isTrue);
  });

  testWidgets(
    'reduced motion renders a flat scrim with no per-frame ticker, '
    'and a one-shot timer drops it at fogUntil',
    (tester) async {
      // `now` is a mutable stand-in for the server-adjusted clock: real
      // `DateTime.now()` is not advanced by `tester.pump`'s fake clock, but
      // the scheduled Timer's delay is a fixed Duration and IS driven by it.
      // Advancing `current` right before the final pump simulates the clock
      // having reached fogUntil by the time the Timer fires and rebuilds.
      var current = DateTime.now();
      final fogUntil = current.add(const Duration(seconds: 2));

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: FogShaderOverlay(fogUntil: fogUntil, now: () => current),
            ),
          ),
        ),
      );

      // Scoped to the overlay's own subtree: Scaffold/Material also build
      // their own ColoredBox/CustomPaint internally.
      final scrimFinder = find.descendant(
        of: find.byType(FogShaderOverlay),
        matching: find.byType(ColoredBox),
      );
      final shaderFinder = find.descendant(
        of: find.byType(FogShaderOverlay),
        matching: find.byType(CustomPaint),
      );

      // Flat scrim renders while active, and no shader CustomPaint is used.
      final scrim = tester.widget<ColoredBox>(scrimFinder);
      expect(scrim.color, AppColors.fogTint);
      expect(shaderFinder, findsNothing);

      // Pumping frames within the active window must not require any
      // per-frame work to keep showing the scrim (no ticker is driving it):
      // the scrim is still there after an arbitrary settle with no timers
      // firing early.
      await tester.pump(const Duration(milliseconds: 500));
      expect(scrimFinder, findsOneWidget);

      // The one-shot timer fires once fogUntil is reached, dropping the
      // scrim. Advance the stand-in clock past fogUntil first so the
      // rebuild the Timer triggers sees `_active` as false.
      current = fogUntil.add(const Duration(milliseconds: 1));
      await tester.pump(const Duration(seconds: 2));
      expect(scrimFinder, findsNothing);
    },
  );
}
