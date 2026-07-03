import 'package:freezed_annotation/freezed_annotation.dart';

part 'player_state.freezed.dart';

/// Summary of the level the player just completed, built from real backend
/// puzzle data at the moment of the win (the puzzle's total answers and how many
/// were found). Drives the level-complete screen's label and progress bar. Null
/// until a level has been completed this session.
@freezed
abstract class LevelSummary with _$LevelSummary {
  const factory LevelSummary({
    /// The progression level that was completed (backend `highestLevel` value).
    required int completedLevel,

    /// Words found in the puzzle (equals [totalWords] on a full completion).
    required int wordsFound,

    /// The puzzle's total answers (`answerCount` from the backend puzzle).
    required int totalWords,
  }) = _LevelSummary;

  const LevelSummary._();

  /// Fill for the progress bar: found answers over total answers.
  double get progressFraction =>
      totalWords == 0 ? 0 : (wordsFound / totalWords).clamp(0, 1);

  String get completedLabel => 'Level $completedLevel Completed!';

  /// The "X/Y" text shown under the bar.
  String get fractionText => '$wordsFound/$totalWords';
}
