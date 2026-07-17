import 'package:agape_logos_game/core/design/tokens/colors.dart';
import 'package:agape_logos_game/features/multiplayer/application/match_providers.dart';
import 'package:agape_logos_game/features/multiplayer/presentation/widgets/active_effect_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const now = 1000000;

  Widget host(MatchActiveEffects effects) => MaterialApp(
    home: Scaffold(
      body: ActiveEffectChips(effects: effects, nowMillis: now),
    ),
  );

  testWidgets('a stacked fog chip shows its multiplier', (tester) async {
    await tester.pumpWidget(host(MatchActiveEffects(
      fog: true,
      fogUntil: DateTime.fromMillisecondsSinceEpoch(now + 8000),
      fogStacks: 2,
    )));
    await tester.pumpAndSettle();
    expect(find.text('Fog x2 8s'), findsOneWidget);
  });

  testWidgets('an expiring chip switches to danger styling', (tester) async {
    await tester.pumpWidget(host(MatchActiveEffects(
      fog: true,
      fogUntil: DateTime.fromMillisecondsSinceEpoch(now + 4000),
      fogStacks: 1,
    )));
    await tester.pumpAndSettle();
    final text = tester.widget<Text>(find.text('Fog 4s'));
    expect(text.style?.color, AppColors.dangerOnPond);
  });

  testWidgets(
      'a chip pop-in actually animates (not a static end-scale render)',
      (tester) async {
    await tester.pumpWidget(host(MatchActiveEffects(
      fog: true,
      fogUntil: DateTime.fromMillisecondsSinceEpoch(now + 8000),
      fogStacks: 1,
    )));

    final scaleFinder = find.ancestor(
      of: find.text('Fog 8s'),
      matching: find.byType(Transform),
    );
    // Read the matrix's raw diagonal entry, not Matrix4.getMaxScaleOnAxis():
    // that helper is a raster/texture-resolution utility that floors its
    // result at 1.0, so it can't distinguish an in-progress sub-1.0 scale-in
    // from the settled value (match_hud_test.dart's badge test, c69300c).
    double chipScale() =>
        tester.widget<Transform>(scaleFinder).transform.storage[0];

    // Mounting IS activation (chips only exist in the tree while active), so
    // the very first frame starts the tween. Probe partway through
    // AppDurations.fast (180ms): AppCurves.pop (easeOutBack) has already
    // overshot past the 1.0 end value by its true midpoint (90ms), so 45ms
    // lands solidly between the 0.8 start and the 1.0 rest value while still
    // being clearly mid-animation, not an endpoint.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 45));
    final midScale = chipScale();
    expect(midScale, greaterThan(0.8));
    expect(midScale, lessThan(1.0));

    await tester.pumpAndSettle();
    expect(chipScale(), 1.0);
  });
}
