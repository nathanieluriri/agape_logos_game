// test/features/player/player_state_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agape_logos_game/features/player/application/player_controller.dart';

void main() {
  test('placeholder player state matches the reference', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final s = container.read(playerStateProvider);
    expect(s.coins, 9999);
    expect(s.nextLevelLabel, 'Lv.26');
    expect(s.completedLabel, 'Level 3 Completed!');
    expect(s.progressFraction, closeTo(5 / 8, 1e-9));
  });
}
