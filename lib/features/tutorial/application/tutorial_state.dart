import 'package:flutter/foundation.dart';

/// Where the first-play tutorial is in its short scripted arc.
enum TutorialPhase { trace, celebrate, done }

/// Immutable snapshot of the first-play tutorial.
///
/// The tutorial walks a brand new player through tracing the first couple of
/// answers on the letter wheel, celebrates once, then gets out of the way.
/// State is plain and hand-rolled (no codegen): it is tiny and changes rarely.
class TutorialState {
  const TutorialState({
    required this.targetWords,
    required this.stepIndex,
    required this.phase,
  });

  /// Uppercase answer words the tutorial prompts, in play order.
  final List<String> targetWords;

  /// Index into [targetWords] of the word currently being prompted.
  final int stepIndex;

  final TutorialPhase phase;

  /// The word the player is being asked to trace right now.
  String get targetWord => targetWords[stepIndex];

  bool get isLastStep => stepIndex == targetWords.length - 1;

  /// Coach copy for the current phase and step. Empty once the tutorial is
  /// done so the UI can fade the pill without a special case.
  String get message {
    switch (phase) {
      case TutorialPhase.trace:
        return stepIndex == 0
            ? 'Drag across the letters to spell $targetWord.'
            : 'Great! Now add the word $targetWord.';
      case TutorialPhase.celebrate:
        return 'Perfect! Find every word to clear the pond.';
      case TutorialPhase.done:
        return '';
    }
  }

  TutorialState copyWith({
    List<String>? targetWords,
    int? stepIndex,
    TutorialPhase? phase,
  }) =>
      TutorialState(
        targetWords: targetWords ?? this.targetWords,
        stepIndex: stepIndex ?? this.stepIndex,
        phase: phase ?? this.phase,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TutorialState &&
          listEquals(other.targetWords, targetWords) &&
          other.stepIndex == stepIndex &&
          other.phase == phase;

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(targetWords), stepIndex, phase);
}

/// Greedily maps each letter of [word] to the first unused index in
/// [wheelLetters], comparing uppercase on both sides. Returns the slot
/// indices in word order, or null when some letter has no unused slot left,
/// so callers can skip the guided trace instead of drawing a broken path.
List<int>? slotsForWord(List<String> wheelLetters, String word) {
  final upper = [for (final l in wheelLetters) l.toUpperCase()];
  final used = List<bool>.filled(upper.length, false);
  final slots = <int>[];
  for (final letter in word.toUpperCase().split('')) {
    var slot = -1;
    for (var i = 0; i < upper.length; i++) {
      if (!used[i] && upper[i] == letter) {
        slot = i;
        break;
      }
    }
    if (slot == -1) return null;
    used[slot] = true;
    slots.add(slot);
  }
  return slots;
}
