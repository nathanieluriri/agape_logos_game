import 'package:freezed_annotation/freezed_annotation.dart';

import '../../puzzles/domain/puzzle.dart';

part 'game_session.freezed.dart';

/// Praise headline for a combo streak (null below 2).
String? praiseForCombo(int combo) {
  if (combo >= 4) return 'Expert!';
  if (combo == 3) return 'Great!';
  if (combo == 2) return 'Good!';
  return null;
}

@freezed
abstract class GameSession with _$GameSession {
  const factory GameSession({
    required Puzzle puzzle,
    required List<int> rackOrder,
    required List<int> selection,
    required Set<String> found,
    required Map<String, int> revealed,
    required int score,
    required int combo,
    required int hintsLeft,
  }) = _GameSession;

  const GameSession._();

  factory GameSession.initial({
    required Puzzle puzzle,
    required int hintsLeft,
  }) =>
      GameSession(
        puzzle: puzzle,
        rackOrder: List<int>.generate(puzzle.letters.length, (i) => i),
        selection: const [],
        found: const {},
        revealed: const {},
        score: 0,
        combo: 0,
        hintsLeft: hintsLeft,
      );

  /// Wheel letters in display order (shuffle permutes rackOrder).
  List<String> get wheelLetters =>
      [for (final i in rackOrder) puzzle.letters[i]];

  /// The in-progress word from the selected wheel slots.
  String get formedWord =>
      [for (final slot in selection) wheelLetters[slot]].join().toUpperCase();

  /// All answers, sorted shortest-first then alphabetically.
  List<PuzzleAnswer> get targets {
    final list = [...puzzle.answers];
    list.sort((a, b) {
      final byLen = a.length.compareTo(b.length);
      return byLen != 0 ? byLen : a.word.compareTo(b.word);
    });
    return list;
  }

  bool get isComplete =>
      puzzle.answers.every((a) => found.contains(a.word.toUpperCase()));

  String? get praise => praiseForCombo(combo);
}
