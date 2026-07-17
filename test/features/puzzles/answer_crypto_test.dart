import 'dart:convert';

import 'package:agape_logos_game/core/crypto/answer_cipher.dart';
import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:agape_logos_game/features/puzzles/data/puzzle_mappers.dart';
import 'package:agape_logos_game/features/puzzles/data/puzzle_remote.dart';
import 'package:agape_logos_game/features/puzzles/data/puzzle_repository_impl.dart';
import 'package:agape_logos_game/features/puzzles/domain/puzzle.dart';
import 'package:cryptography/cryptography.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Produces a wire token in the exact backend format:
/// base64( iv(12) | ciphertext | tag(16) ), AES-256-GCM.
Future<String> _token(List<int> key, Map<String, dynamic> payload) async {
  final algo = AesGcm.with256bits();
  final box = await algo.encrypt(
    utf8.encode(jsonEncode(payload)),
    secretKey: SecretKey(key),
  );
  return base64Encode([...box.nonce, ...box.cipherText, ...box.mac.bytes]);
}

class _FakeRemote implements PuzzleRemote {
  @override
  Future<List<Puzzle>> draw(Map<String, int> composition) async => const [];
  @override
  Future<List<Puzzle>> assignedIncomplete() async => const [];
}

void main() {
  final key = List<int>.generate(32, (i) => i + 1);

  test('AnswerCipher round-trips a backend-format token', () async {
    final token = await _token(key, {'w': 'POND', 'd': 'a small lake'});
    final cipher = AnswerCipher();
    final answer = await cipher.decryptAnswer(key, token);
    expect(answer.word, 'POND');
    expect(answer.definition, 'a small lake');
  });

  test('the wrong key fails to decrypt', () async {
    final token = await _token(key, {'w': 'POND', 'd': null});
    final wrong = List<int>.generate(32, (i) => 99);
    expect(() => AnswerCipher().decryptAnswer(wrong, token), throwsA(anything));
  });

  test('wirePuzzleToEncrypted parks the ciphertext in word and keeps length',
      () {
    final puzzle = wirePuzzleToEncrypted({
      'tier': 'easy',
      'rackSize': 4,
      'letters': ['P', 'O', 'N', 'D'],
      'letterKey': 'DNOP',
      'anchor': 'POND',
      'answers': [
        {'length': 4, 'enc': 'tok'},
      ],
      'answerCount': 1,
    });
    expect(puzzle.answers.single.word, 'tok'); // ciphertext token, not plaintext
    expect(puzzle.answers.single.length, 4);
    expect(puzzle.answers.single.definition, isNull);
  });

  test('repository decrypts an encrypted puzzle at the read seam', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    // Ciphertext carries the definition too, so the read-seam guard keeps the
    // decrypted words (it drops any left undefined). Two answers clears the
    // >= kMinPlayableAnswers floor.
    final pondToken = await _token(key, {'w': 'POND', 'd': 'a small lake'});
    final donToken = await _token(key, {'w': 'DON', 'd': 'a Spanish title'});
    // Cache an encrypted puzzle whose answer words hold the ciphertext tokens.
    final encryptedPuzzle = Puzzle(
      tier: 'easy',
      rackSize: 4,
      letters: const ['P', 'O', 'N', 'D'],
      letterKey: 'DNOP',
      anchor: 'POND',
      answers: [
        PuzzleAnswer(word: pondToken, length: 4, definition: null),
        PuzzleAnswer(word: donToken, length: 3, definition: null),
      ],
      answerCount: 2,
    );
    await db.cachedPuzzlesDao.insertAll([
      puzzleToCompanion(encryptedPuzzle,
          orderIndex: 0, assignedAt: 0, encrypted: true),
    ]);

    final repo = PuzzleRepositoryImpl(
      db,
      _FakeRemote(),
      answerKey: () async => key,
    );

    final decrypted = await repo.watchCurrentPuzzle().first;
    expect(decrypted, isNotNull);
    expect(decrypted!.answers.length, 2);
    expect(decrypted.answers.first.word, 'POND'); // plaintext in memory only
    expect(decrypted.answers.first.definition, 'a small lake');
    expect(decrypted.answers.first.length, 4);
  });

  test('an encrypted puzzle is withheld when no key is available', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final token = await _token(key, {'w': 'POND', 'd': null});
    await db.cachedPuzzlesDao.insertAll([
      puzzleToCompanion(
        Puzzle(
          tier: 'easy',
          rackSize: 4,
          letters: const ['P', 'O', 'N', 'D'],
          letterKey: 'DNOP',
          anchor: 'POND',
          answers: [PuzzleAnswer(word: token, length: 4, definition: null)],
          answerCount: 1,
        ),
        orderIndex: 0,
        assignedAt: 0,
        encrypted: true,
      ),
    ]);

    // No answerKey provided -> defaults to null -> puzzle not playable.
    final repo = PuzzleRepositoryImpl(db, _FakeRemote());
    expect(await repo.watchCurrentPuzzle().first, isNull);
  });
}
