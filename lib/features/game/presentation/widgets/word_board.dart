import 'package:flutter/material.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/sizing.dart';
import '../../../puzzles/domain/puzzle.dart';

/// The target-word board: one row per answer, cells fill in as words are found
/// (or hint-revealed).
class WordBoard extends StatelessWidget {
  const WordBoard({
    super.key,
    required this.targets,
    required this.found,
    required this.revealed,
  });

  final List<PuzzleAnswer> targets;
  final Set<String> found;
  final Map<String, int> revealed;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final answer in targets)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizing.boardTileGap / 2),
              child: _WordRow(
                word: answer.word.toUpperCase(),
                found: found.contains(answer.word.toUpperCase()),
                revealed: revealed[answer.word.toUpperCase()] ?? 0,
              ),
            ),
        ],
      ),
    );
  }
}

class _WordRow extends StatelessWidget {
  const _WordRow({
    required this.word,
    required this.found,
    required this.revealed,
  });

  final String word;
  final bool found;
  final int revealed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < word.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizing.boardTileGap / 2),
            child: _Tile(letter: word[i], filled: found || i < revealed),
          ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.letter, required this.filled});
  final String letter;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.normal,
      width: AppSizing.boardTile,
      height: AppSizing.boardTile,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? AppColors.tileBlue : AppColors.slotEmpty,
        borderRadius: AppRadii.card,
      ),
      child: filled
          ? Text(
              letter,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.tileBlueText,
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
