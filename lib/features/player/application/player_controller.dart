import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'player_state.dart';

/// Holds the placeholder player state. Swappable with real game state later.
class PlayerController extends Notifier<PlayerState> {
  @override
  PlayerState build() => const PlayerState(
        coins: 9999,
        currentLevel: 26,
        progressDone: 5,
        progressTotal: 8,
        lastCompletedLevel: 3,
      );

  /// Advance progression after finishing the current level.
  void completeLevel({required int coinsAwarded}) {
    state = state.copyWith(
      coins: state.coins + coinsAwarded,
      lastCompletedLevel: state.currentLevel,
      currentLevel: state.currentLevel + 1,
      progressDone: 0,
    );
  }
}

final playerStateProvider =
    NotifierProvider<PlayerController, PlayerState>(PlayerController.new);
