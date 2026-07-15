import 'package:freezed_annotation/freezed_annotation.dart';

part 'match_settings.freezed.dart';

enum MatchDifficulty { easy, medium, hard }

/// Live = both players in the same sitting (real-time). Async = a 6-hour
/// challenge played across sittings. Only the server sets `async` on a
/// challenge; everything the client creates defaults to `live`.
enum MatchMode { live, async }

MatchDifficulty matchDifficultyFromWire(String? raw) {
  switch (raw) {
    case 'easy':
      return MatchDifficulty.easy;
    case 'hard':
      return MatchDifficulty.hard;
    default:
      return MatchDifficulty.medium;
  }
}

/// Creator-chosen match settings (contract 8.2 `settings` block). Only the
/// creator sets these; the joiner inherits them from the match doc.
@freezed
abstract class MatchSettings with _$MatchSettings {
  const factory MatchSettings({
    required MatchDifficulty difficulty,
    required int durationSec,
    required int rackSize,
    String? theme,
    @Default(MatchMode.live) MatchMode mode,
  }) = _MatchSettings;

  const MatchSettings._();

  factory MatchSettings.defaults() => const MatchSettings(
    difficulty: MatchDifficulty.medium,
    durationSec: 120,
    rackSize: 7,
    theme: null,
    mode: MatchMode.live,
  );

  /// Wire form for the `POST /matches` body (contract 8.7). `difficulty` is the
  /// enum name (`easy|medium|hard`, contract 8.2).
  Map<String, dynamic> toWire() => <String, dynamic>{
    'difficulty': difficulty.name,
    'durationSec': durationSec,
    'rackSize': rackSize,
    'theme': theme,
    'mode': mode.name,
  };
}
