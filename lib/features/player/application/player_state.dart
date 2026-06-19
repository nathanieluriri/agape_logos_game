import 'package:freezed_annotation/freezed_annotation.dart';

part 'player_state.freezed.dart';

/// Placeholder cross-page player state (wallet + level progress). Both the
/// home and level-complete pages read this. No backend yet.
@freezed
abstract class PlayerState with _$PlayerState {
  const factory PlayerState({
    required int coins,
    required int currentLevel,
    required int progressDone,
    required int progressTotal,
    required int lastCompletedLevel,
  }) = _PlayerState;

  const PlayerState._();

  double get progressFraction =>
      progressTotal == 0 ? 0 : (progressDone / progressTotal).clamp(0, 1);

  String get nextLevelLabel => 'Lv.$currentLevel';

  String get completedLabel => 'Level $lastCompletedLevel Completed!';
}
