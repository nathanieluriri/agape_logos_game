import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_state.freezed.dart';

/// Reactive home-screen data. Placeholder values today; swap the controller body
/// for real game state later without touching any widget.
@freezed
abstract class HomeState with _$HomeState {
  const HomeState._();

  const factory HomeState({
    required int currency,
    required String levelLabel,
    required int progressDone,
    required int progressTotal,
    required String nextLevelLabel,
  }) = _HomeState;

  /// Fill ratio for the progress bar, clamped to [0, 1].
  double get progressFraction =>
      progressTotal <= 0 ? 0 : (progressDone / progressTotal).clamp(0, 1);
}
