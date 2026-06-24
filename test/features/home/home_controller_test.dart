import 'package:agape_logos_game/features/home/application/home_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('home controller exposes placeholder defaults', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    final state = c.read(homeControllerProvider);
    expect(state.currency, 9999);
    expect(state.levelLabel, 'Level 3 Completed!');
    expect(state.progressDone, 5);
    expect(state.progressTotal, 8);
    expect(state.nextLevelLabel, 'Lv.26');
  });

  test('progressFraction is done over total, clamped', () {
    const state = HomeController.placeholder;
    expect(state.progressFraction, closeTo(5 / 8, 1e-9));
  });
}
