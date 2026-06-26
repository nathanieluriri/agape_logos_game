import 'package:freezed_annotation/freezed_annotation.dart';

part 'puzzle.freezed.dart';
part 'puzzle.g.dart';

@freezed
abstract class PuzzleAnswer with _$PuzzleAnswer {
  const factory PuzzleAnswer({
    required String word,
    required int length,
    required String? definition,
  }) = _PuzzleAnswer;

  factory PuzzleAnswer.fromJson(Map<String, dynamic> json) =>
      _$PuzzleAnswerFromJson(json);
}

@freezed
abstract class Puzzle with _$Puzzle {
  const factory Puzzle({
    required String tier,
    required int rackSize,
    required List<String> letters,
    required String letterKey,
    required String anchor,
    required List<PuzzleAnswer> answers,
    required int answerCount,
  }) = _Puzzle;

  factory Puzzle.fromJson(Map<String, dynamic> json) => _$PuzzleFromJson(json);
}
