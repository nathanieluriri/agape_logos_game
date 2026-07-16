import 'package:agape_logos_game/core/design/tokens/gradients.dart';
import 'package:agape_logos_game/features/multiplayer/presentation/widgets/powerup_side_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('side buttons use the teal settings disc, not the cream pad', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PowerupSideButtons(onOpen: (_) {}),
        ),
      ),
    );

    final gradients = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .map((d) => d.gradient)
        .whereType<Gradient>()
        .toList();

    expect(gradients, contains(AppGradients.settingsInner));
    expect(gradients, isNot(contains(AppGradients.wheelPad)));
  });
}
