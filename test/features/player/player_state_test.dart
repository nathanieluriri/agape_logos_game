// test/features/player/player_state_test.dart
import 'package:agape_logos_game/features/player/application/player_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no completion recorded yet -> null summary', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(levelCompletionProvider), isNull);
  });

  test('recordCompletion builds a summary with real fraction and labels', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(levelCompletionProvider.notifier).recordCompletion(
          completedLevel: 7,
          wordsFound: 6,
          totalWords: 8,
        );

    final s = container.read(levelCompletionProvider)!;
    expect(s.completedLabel, 'Level 7 Completed!');
    expect(s.fractionText, '6/8');
    expect(s.progressFraction, closeTo(6 / 8, 1e-9));
  });
}
