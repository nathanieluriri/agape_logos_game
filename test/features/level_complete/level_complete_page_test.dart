// test/features/level_complete/level_complete_page_test.dart
import 'package:agape_logos_game/features/level_complete/presentation/pages/level_complete_page.dart';
import 'package:agape_logos_game/features/level_complete/presentation/widgets/level_progress_bar.dart';
import 'package:agape_logos_game/features/player/application/player_controller.dart';
import 'package:agape_logos_game/features/profile/application/profile_providers.dart';
import 'package:agape_logos_game/game/ambient/ambient_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the real completion summary + Bonus, no Withdraw',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        ambientEnabledProvider.overrideWithValue(false),
        coinsProvider.overrideWithValue(0),
        nextLevelProvider.overrideWithValue(4),
      ],
      child: const MaterialApp(home: LevelCompletePage()),
    ));

    // Seed the summary the game controller would have recorded on the win.
    final container =
        ProviderScope.containerOf(tester.element(find.byType(LevelCompletePage)));
    container.read(levelCompletionProvider.notifier).recordCompletion(
          completedLevel: 3,
          wordsFound: 8,
          totalWords: 8,
        );
    await tester.pump();

    expect(find.byType(LevelProgressBar), findsOneWidget);
    expect(find.text('Level 3 Completed!'), findsOneWidget);
    expect(find.text('8/8'), findsOneWidget);
    expect(find.bySemanticsLabel('Bonus Gift'), findsOneWidget);
    expect(find.bySemanticsLabel('Withdraw'), findsNothing);
  });
}
