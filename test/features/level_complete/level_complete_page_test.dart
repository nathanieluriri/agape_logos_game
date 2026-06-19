// test/features/level_complete/level_complete_page_test.dart
import 'package:agape_logos_game/features/home/presentation/widgets/home_background.dart';
import 'package:agape_logos_game/features/level_complete/presentation/pages/level_complete_page.dart';
import 'package:agape_logos_game/features/level_complete/presentation/widgets/level_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows progress + Bonus, no Withdraw', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [homeAmbientEnabledProvider.overrideWithValue(false)],
      child: const MaterialApp(home: LevelCompletePage()),
    ));
    await tester.pump();

    expect(find.byType(LevelProgressBar), findsOneWidget);
    expect(find.text('Level 3 Completed!'), findsOneWidget);
    expect(find.bySemanticsLabel('Bonus Gift'), findsOneWidget);
    expect(find.bySemanticsLabel('Withdraw'), findsNothing);
  });
}
