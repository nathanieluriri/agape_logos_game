import 'package:agape_logos_game/features/tutorial/application/tutorial_state.dart';
import 'package:flutter_test/flutter_test.dart';

const _base = TutorialState(
  targetWords: ['FI', 'IF'],
  stepIndex: 0,
  phase: TutorialPhase.trace,
);

void main() {
  group('message', () {
    test('first trace step teaches the drag gesture', () {
      expect(_base.message, 'Drag across the letters to spell FI.');
    });

    test('later trace steps prompt the next word', () {
      final s = _base.copyWith(stepIndex: 1);
      expect(s.message, 'Great! Now add the word IF.');
      expect(s.targetWord, 'IF');
      expect(s.isLastStep, isTrue);
    });

    test('celebrate hands the pond back to the player', () {
      final s = _base.copyWith(phase: TutorialPhase.celebrate);
      expect(s.message, 'Perfect! Find every word to clear the pond.');
    });

    test('done is empty so the pill can simply fade', () {
      expect(_base.copyWith(phase: TutorialPhase.done).message, isEmpty);
    });
  });

  group('equality', () {
    test('value-equal states compare equal with matching hashCodes', () {
      const other = TutorialState(
        targetWords: ['FI', 'IF'],
        stepIndex: 0,
        phase: TutorialPhase.trace,
      );
      expect(_base, other);
      expect(_base.hashCode, other.hashCode);
      expect(_base, isNot(_base.copyWith(stepIndex: 1)));
    });
  });

  group('slotsForWord', () {
    test('maps each letter to a wheel slot in word order', () {
      expect(slotsForWord(['C', 'A', 'T'], 'CAT'), [0, 1, 2]);
      expect(slotsForWord(['T', 'A', 'C'], 'CAT'), [2, 1, 0]);
    });

    test('compares uppercase on both sides', () {
      expect(slotsForWord(['c', 'a', 't'], 'tac'), [2, 1, 0]);
    });

    test('repeated letters consume distinct slots greedily', () {
      expect(slotsForWord(['T', 'O', 'O', 'T'], 'TOOT'), [0, 1, 2, 3]);
      expect(slotsForWord(['T', 'O', 'O', 'T'], 'OTTO'), [1, 0, 3, 2]);
    });

    test('returns null when a letter has no unused slot', () {
      expect(slotsForWord(['C', 'A', 'T'], 'CATS'), isNull);
      expect(slotsForWord(['T', 'O', 'T'], 'TOOT'), isNull);
    });
  });
}
