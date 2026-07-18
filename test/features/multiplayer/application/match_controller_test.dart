import 'package:agape_logos_game/features/multiplayer/application/match_controller.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match_rack.dart';
import 'package:agape_logos_game/features/puzzles/domain/puzzle.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

MatchRack _rack({List<String> found = const []}) => MatchRack(
      uid: 'me', letters: const ['T', 'E', 'A', 'R'], letterKey: 'AERT',
      rackSize: 4,
      answers: const [
        PuzzleAnswer(word: 'TEAR', length: 4, definition: null),
        PuzzleAnswer(word: 'RATE', length: 4, definition: null),
      ],
      answerCount: 2, foundWords: found,
    );

void main() {
  late ProviderContainer c;
  late MatchPlayController ctrl;
  setUp(() {
    c = ProviderContainer();
    ctrl = c.read(matchPlayControllerProvider.notifier);
    ctrl.syncRack(_rack());
  });
  tearDown(() => c.dispose());

  test('valid word is returned to submit + added to pendingFound', () {
    ctrl.touchLetter(0); // T
    ctrl.touchLetter(1); // E
    ctrl.touchLetter(2); // A
    ctrl.touchLetter(3); // R
    final word = ctrl.endSelection(_rack(), <String>{});
    expect(word, 'TEAR');
    expect(c.read(matchPlayControllerProvider).pendingFound, contains('TEAR'));
  });

  test('invalid word returns null and does not record', () {
    ctrl.touchLetter(3); // R
    ctrl.touchLetter(0); // T
    expect(ctrl.endSelection(_rack(), <String>{}), isNull);
    expect(c.read(matchPlayControllerProvider).pendingFound, isEmpty);
  });

  test('frozen slot is ignored on touch', () {
    ctrl.touchLetter(0, frozen: {0});
    expect(c.read(matchPlayControllerProvider).selection, isEmpty);
  });

  test('syncRack drops an optimistic word the server confirmed', () {
    ctrl.touchLetter(0);
    ctrl.touchLetter(1);
    ctrl.touchLetter(2);
    ctrl.touchLetter(3);
    ctrl.endSelection(_rack(), <String>{});
    expect(c.read(matchPlayControllerProvider).pendingFound, contains('TEAR'));
    ctrl.syncRack(_rack(found: ['TEAR'])); // server caught up
    expect(c.read(matchPlayControllerProvider).pendingFound, isEmpty);
  });

  test('a rejected submit rolls the word back and clears the duplicate guard', () {
    ctrl.touchLetter(0); // T
    ctrl.touchLetter(1); // E
    ctrl.touchLetter(2); // A
    ctrl.touchLetter(3); // R
    expect(ctrl.endSelection(_rack(), <String>{}), 'TEAR');
    expect(c.read(matchPlayControllerProvider).pendingFound, contains('TEAR'));

    // Server rejected it (frozen / not_active / duplicate / steal race) or the
    // submit never arrived (offline / 5xx): roll the optimistic word back.
    ctrl.rollbackSubmit('TEAR');
    // The board no longer shows an uncredited word.
    expect(c.read(matchPlayControllerProvider).pendingFound, isEmpty);

    // The duplicate guard is cleared: the SAME word can be re-traced and
    // re-submitted later (e.g. once a freeze thaws or connectivity returns).
    ctrl.touchLetter(0);
    ctrl.touchLetter(1);
    ctrl.touchLetter(2);
    ctrl.touchLetter(3);
    expect(ctrl.endSelection(_rack(), <String>{}), 'TEAR');
    expect(c.read(matchPlayControllerProvider).pendingFound, contains('TEAR'));
  });

  test('a failed submit leaves no phantom found word after a rack tick', () {
    ctrl.touchLetter(0);
    ctrl.touchLetter(1);
    ctrl.touchLetter(2);
    ctrl.touchLetter(3);
    ctrl.endSelection(_rack(), <String>{});
    ctrl.rollbackSubmit('TEAR');
    // A later rack tick that does NOT confirm the word must not resurrect it.
    ctrl.syncRack(_rack(found: const []));
    expect(c.read(matchPlayControllerProvider).pendingFound, isEmpty);
  });

  test('rollbackSubmit for an absent word is a harmless no-op', () {
    ctrl.rollbackSubmit('NONE');
    expect(c.read(matchPlayControllerProvider).pendingFound, isEmpty);
  });

  test('a successful submit keeps the word until syncRack confirms it', () {
    ctrl.touchLetter(0);
    ctrl.touchLetter(1);
    ctrl.touchLetter(2);
    ctrl.touchLetter(3);
    ctrl.endSelection(_rack(), <String>{});
    // No rollback (submit succeeded). The optimistic word stays put across a
    // rack tick that has not yet included it.
    ctrl.syncRack(_rack(found: const []));
    expect(c.read(matchPlayControllerProvider).pendingFound, contains('TEAR'));
    // Once the server confirms it, syncRack drops the optimistic copy.
    ctrl.syncRack(_rack(found: const ['TEAR']));
    expect(c.read(matchPlayControllerProvider).pendingFound, isEmpty);
  });

  test('scramble + word-steal apply once per event id', () {
    final before = [...c.read(matchPlayControllerProvider).rackOrder];
    ctrl.applyScramble('e1');
    ctrl.applyScramble('e1'); // duplicate ignored
    expect(c.read(matchPlayControllerProvider).appliedEventIds, {'e1'});
    ctrl.touchLetter(0);
    ctrl.touchLetter(1);
    ctrl.touchLetter(2);
    ctrl.touchLetter(3);
    ctrl.endSelection(_rack(), <String>{});
    ctrl.applyWordSteal('e2', 'tear');
    expect(c.read(matchPlayControllerProvider).pendingFound, isEmpty);
    expect(before.length, 4);
  });
}
