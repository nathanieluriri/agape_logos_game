import 'package:agape_logos_game/features/home/presentation/widgets/home_branding.dart';
import 'package:agape_logos_game/features/home/presentation/widgets/level_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders label, count, and a default branding title',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [HomeBranding(), LevelProgress()],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('ZEN WORD'), findsOneWidget);
    expect(find.text('Level 3 Completed!'), findsOneWidget);
    expect(find.text('5 / 8'), findsOneWidget);
  });
}
