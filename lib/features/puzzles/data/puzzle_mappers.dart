import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../../core/storage/app_database.dart';
import '../domain/puzzle.dart';

int tierRankOf(String tier) {
  switch (tier) {
    case 'easy':
      return 0;
    case 'medium':
      return 1;
    case 'hard':
      return 2;
    case 'expert':
      return 3;
    default:
      return 99;
  }
}

Puzzle puzzleFromRow(CachedPuzzleRow row) {
  final letters = (jsonDecode(row.lettersJson) as List).cast<String>();
  final answers = (jsonDecode(row.answersJson) as List)
      .map((e) => PuzzleAnswer.fromJson((e as Map).cast<String, dynamic>()))
      .toList();
  return Puzzle(
    tier: row.tier,
    rackSize: row.rackSize,
    letters: letters,
    letterKey: row.puzzleId,
    anchor: row.anchor,
    answers: answers,
    answerCount: row.answerCount,
  );
}

CachedPuzzlesCompanion puzzleToCompanion(
  Puzzle p, {
  required int orderIndex,
  required int assignedAt,
  required bool encrypted,
}) {
  return CachedPuzzlesCompanion.insert(
    puzzleId: p.letterKey,
    tier: p.tier,
    tierRank: tierRankOf(p.tier),
    rackSize: p.rackSize,
    lettersJson: jsonEncode(p.letters),
    anchor: p.anchor,
    // For encrypted puzzles each answer's `word` holds its ciphertext token, so
    // the stored JSON is ciphertext at rest; the read seam decrypts it.
    answersJson: jsonEncode(p.answers.map((a) => a.toJson()).toList()),
    answerCount: p.answerCount,
    orderIndex: orderIndex,
    assignedAt: assignedAt,
    encrypted: Value(encrypted),
  );
}
