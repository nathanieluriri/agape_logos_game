// lib/preview/game_previews.dart
//
// Design previews for the game screen. Run with:
//   flutter widget-preview start
// (or open the Widget Previews panel in the IDE on Flutter 3.38+).
//
// These are static, provider-free compositions: the previewer runs on
// Flutter Web, so nothing here may import bootstrap, Drift, or the Flame
// ambient layer.
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../core/design/tokens/gradients.dart';
import '../core/design/tokens/spacing.dart';
import '../features/game/presentation/widgets/combo_banner.dart';
import '../features/game/presentation/widgets/formed_word_pill.dart';
import '../features/game/presentation/widgets/game_top_bar.dart';
import '../features/game/presentation/widgets/letter_wheel.dart';
import '../features/game/presentation/widgets/wheel_action_button.dart';
import '../features/game/presentation/widgets/word_board.dart';
import '../features/puzzles/domain/puzzle.dart';

Widget _stage({double width = 390, double height = 844, required Widget child}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Center(
      child: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppGradients.pond),
          child: child,
        ),
      ),
    ),
  );
}

/// Sample targets: one found, one partially hint-revealed, one untouched.
const _answers = [
  PuzzleAnswer(word: 'POND', length: 4, definition: null),
  PuzzleAnswer(word: 'PODS', length: 4, definition: null),
  PuzzleAnswer(word: 'SNAP', length: 4, definition: null),
];

@Preview(name: 'Game screen (static)')
Widget gameScreenPreview() {
  return _stage(
    child: Column(
      children: [
        GameTopBar(
          level: 26,
          coins: 9999,
          onBack: () {},
          onDictionary: () {},
        ),
        const Expanded(
          child: WordBoard(
            targets: _answers,
            found: {'POND'},
            revealed: {'PODS': 2},
          ),
        ),
        const ComboBanner(praise: 'Great!', combo: 3),
        const FormedWordPill(word: 'POND'),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.lg,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                WheelActionButton(
                  icon: Icons.shuffle,
                  semanticLabel: 'Shuffle',
                  onTap: () {},
                ),
                const SizedBox(width: AppSpacing.lg),
                LetterWheel(
                  letters: const ['P', 'O', 'N', 'D', 'S'],
                  selected: const [0, 1],
                  onTouch: (_) {},
                  onEnd: () {},
                ),
                const SizedBox(width: AppSpacing.lg),
                WheelActionButton(
                  icon: Icons.lightbulb_outline,
                  semanticLabel: 'Hint',
                  onTap: () {},
                  badge: 2,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

@Preview(name: 'Word board states')
Widget wordBoardStatesPreview() {
  return _stage(
    height: 360,
    child: const Center(
      child: WordBoard(
        targets: _answers,
        found: {'POND'},
        revealed: {'PODS': 2},
      ),
    ),
  );
}
