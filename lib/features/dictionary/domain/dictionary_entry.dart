/// One solved word in the player's dictionary: the word, its definition (may be
/// null in the pool), the tier of the puzzle it came from, and the progression
/// level it was solved at (null when the server does not retain it). Plain and
/// immutable (no codegen), like the store/rewards models.
class DictionaryEntry {
  const DictionaryEntry({
    required this.word,
    required this.definition,
    required this.tier,
    required this.level,
  });

  final String word;
  final String? definition;
  final String tier;
  final int? level;

  factory DictionaryEntry.fromJson(Map<String, dynamic> json) =>
      DictionaryEntry(
        word: json['word'] as String,
        definition: json['definition'] as String?,
        tier: (json['tier'] as String?) ?? 'easy',
        level: (json['level'] as num?)?.toInt(),
      );
}
