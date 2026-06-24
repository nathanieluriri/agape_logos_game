// test/features/level_complete/level_progress_bar_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agape_logos_game/features/level_complete/presentation/widgets/level_progress_bar.dart';

void main() {
  testWidgets('LevelProgressBar shows label and fraction', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: LevelProgressBar(
            label: 'Level 3 Completed!',
            fraction: 0.625,
            fractionText: '5/8',
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Level 3 Completed!'), findsOneWidget);
    expect(find.text('5/8'), findsOneWidget);
  });
}
