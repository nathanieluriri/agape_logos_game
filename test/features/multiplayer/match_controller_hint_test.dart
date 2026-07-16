import 'package:agape_logos_game/features/multiplayer/application/match_controller.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match_rack.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hint reveals one more letter of an unfound word each call', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(matchPlayControllerProvider.notifier);
    final rack = MatchRack.test(letters: ['C', 'A', 'T'], answers: ['CAT']);
    ctrl.syncRack(rack);

    ctrl.hint(rack, const <String>{});
    expect(container.read(matchPlayControllerProvider).revealed['CAT'], 1);

    ctrl.hint(rack, const <String>{});
    expect(container.read(matchPlayControllerProvider).revealed['CAT'], 2);
  });

  test('hint does nothing when every target is found', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(matchPlayControllerProvider.notifier);
    final rack = MatchRack.test(letters: ['C', 'A', 'T'], answers: ['CAT']);
    ctrl.syncRack(rack);

    ctrl.hint(rack, const {'CAT'});
    expect(container.read(matchPlayControllerProvider).revealed, isEmpty);
  });
}
