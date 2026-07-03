import '../domain/puzzle.dart';
import '../puzzles_config.dart';

/// Enforces the product rule that every surfaced word carries a definition.
///
/// Drops answers whose definition is missing or blank and recomputes
/// [Puzzle.answerCount] over what remains. Returns null when fewer than
/// [kMinPlayableAnswers] defined answers survive, signalling the caller to skip
/// the whole puzzle rather than present a threadbare board.
Puzzle? guardDefinedAnswers(Puzzle puzzle) {
  final defined = <PuzzleAnswer>[
    for (final answer in puzzle.answers)
      if ((answer.definition ?? '').trim().isNotEmpty) answer,
  ];
  if (defined.length < kMinPlayableAnswers) return null;
  if (defined.length == puzzle.answers.length) return puzzle;
  return puzzle.copyWith(answers: defined, answerCount: defined.length);
}
