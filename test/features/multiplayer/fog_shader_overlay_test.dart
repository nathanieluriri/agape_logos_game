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
}
