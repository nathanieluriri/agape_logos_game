import 'package:freezed_annotation/freezed_annotation.dart';

part 'level_result.freezed.dart';
part 'level_result.g.dart';

/// Domain entity for a completed level. `synced` reflects whether the optimistic
/// write has been confirmed by the server.
@freezed
abstract class LevelResult with _$LevelResult {
  const factory LevelResult({
    required String id,
    required int levelId,
    required int score,
    required int completedAt,
    @Default(false) bool synced,
  }) = _LevelResult;

  factory LevelResult.fromJson(Map<String, dynamic> json) =>
      _$LevelResultFromJson(json);
}
