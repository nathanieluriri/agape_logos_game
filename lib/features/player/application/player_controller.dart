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
}

final playerStateProvider =
    NotifierProvider<PlayerController, PlayerState>(PlayerController.new);
