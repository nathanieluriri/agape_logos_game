// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'puzzle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PuzzleAnswer _$PuzzleAnswerFromJson(Map<String, dynamic> json) =>
    _PuzzleAnswer(
      word: json['word'] as String,
      length: (json['length'] as num).toInt(),
      definition: json['definition'] as String?,
    );

Map<String, dynamic> _$PuzzleAnswerToJson(_PuzzleAnswer instance) =>
    <String, dynamic>{
      'word': instance.word,
      'length': instance.length,
      'definition': instance.definition,
    };

_Puzzle _$PuzzleFromJson(Map<String, dynamic> json) => _Puzzle(
  tier: json['tier'] as String,
  rackSize: (json['rackSize'] as num).toInt(),
  letters: (json['letters'] as List<dynamic>).map((e) => e as String).toList(),
  letterKey: json['letterKey'] as String,
  anchor: json['anchor'] as String,
  answers: (json['answers'] as List<dynamic>)
      .map((e) => PuzzleAnswer.fromJson(e as Map<String, dynamic>))
      .toList(),
  answerCount: (json['answerCount'] as num).toInt(),
);

Map<String, dynamic> _$PuzzleToJson(_Puzzle instance) => <String, dynamic>{
  'tier': instance.tier,
  'rackSize': instance.rackSize,
  'letters': instance.letters,
  'letterKey': instance.letterKey,
  'anchor': instance.anchor,
  'answers': instance.answers,
  'answerCount': instance.answerCount,
};
