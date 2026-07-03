import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../core/crypto/answer_cipher.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/offline/mutation.dart';
import '../../../core/offline/offline_aware_repository.dart';
import '../../../core/storage/app_database.dart';
import '../puzzles_config.dart';
import '../domain/puzzle.dart';
import '../domain/puzzle_repository.dart';
import 'puzzle_mappers.dart';
import 'puzzle_remote.dart';
import 'puzzle_seed.dart';

Future<List<int>?> _noKey() async => null;

class PuzzleRepositoryImpl
    with OfflineAwareRepository
    implements PuzzleRepository {
  PuzzleRepositoryImpl(
    this.db,
    this._remote, {
    Uuid? uuid,
    PuzzleSeedSource? seed,
    AnswerCipher? cipher,
    Future<List<int>?> Function()? answerKey,
  })  : _uuid = uuid ?? const Uuid(),
        _seed = seed ?? const BundledPuzzleSeedSource(),
        _cipher = cipher ?? AnswerCipher(),
        _answerKey = answerKey ?? _noKey;

  @override
  final AppDatabase db;
  final PuzzleRemote _remote;
  final Uuid _uuid;
  final PuzzleSeedSource _seed;
  final AnswerCipher _cipher;

  /// Supplies the current user's answer key (from secure storage), or null when
  /// signed out / offline before the key was ever fetched.
  final Future<List<int>?> Function() _answerKey;

  @override
  Future<void> ensureCacheReady() async {
    try {
      if (await db.cachedPuzzlesDao.unplayedCount() == 0) {
        final recovered = await _remote.assignedIncomplete();
        if (recovered.isNotEmpty) await _insert(recovered, encrypted: true);
      }
      if (await db.cachedPuzzlesDao.unplayedCount() < kRefillThreshold) {
        final drawn = await _remote.draw(kDrawComposition);
        if (drawn.isNotEmpty) await _insert(drawn, encrypted: true);
      }
    } on DioException catch (e) {
      // Offline or transient: leave the cache as-is and play what we have.
      logger.info('puzzle cache refill skipped: ${e.message}');
    }
    // Fresh install with no connectivity yet (or a dead backend): fall back
    // to the small bundled starter pack so the game page never sits on an
    // empty-cache spinner before the first successful sync.
    if (await db.cachedPuzzlesDao.unplayedCount() == 0) {
      // Bundled starter answers are plaintext (offline last resort).
      final starter = await _seed.load();
      if (starter.isNotEmpty) await _insert(starter, encrypted: false);
    }
  }

  Future<void> _insert(List<Puzzle> puzzles, {required bool encrypted}) async {
    var idx = await db.cachedPuzzlesDao.nextOrderIndex();
    final now = DateTime.now().millisecondsSinceEpoch;
    final rows = [
      for (final p in puzzles)
        puzzleToCompanion(
          p,
          orderIndex: idx++,
          assignedAt: now,
          encrypted: encrypted,
        ),
    ];
    await db.cachedPuzzlesDao.insertAll(rows);
  }

  @override
  Stream<Puzzle?> watchCurrentPuzzle() =>
      db.cachedPuzzlesDao.watchCurrentPuzzle().asyncMap((row) async {
        if (row == null) return null;
        final puzzle = puzzleFromRow(row);
        if (!row.encrypted) return puzzle;
        return _decryptAnswers(puzzle);
      });

  /// Decrypts an encrypted puzzle's answers in memory using the current user's
  /// key. Returns null (puzzle not playable) when the key is unavailable or a
  /// token fails to decrypt, so the UI shows a retry rather than ciphertext.
  Future<Puzzle?> _decryptAnswers(Puzzle puzzle) async {
    final key = await _answerKey();
    if (key == null) {
      logger.info('answer key unavailable; puzzle held until key is fetched');
      return null;
    }
    try {
      final decrypted = <PuzzleAnswer>[];
      for (final a in puzzle.answers) {
        final r = await _cipher.decryptAnswer(key, a.word);
        decrypted.add(
          PuzzleAnswer(word: r.word, length: a.length, definition: r.definition),
        );
      }
      return puzzle.copyWith(answers: decrypted);
    } catch (e) {
      logger.warning('answer decryption failed: $e');
      return null;
    }
  }

  @override
  Future<Map<String, int>> remainingByTier() =>
      db.cachedPuzzlesDao.remainingByTier();

  @override
  Future<void> recordPuzzleResult(
    String puzzleId,
    int score,
    int completedAt, {
    int? level,
  }) async {
    await db.cachedPuzzlesDao.markCompleted(puzzleId);
    // Bundled starter puzzles are local-only: the backend never assigned
    // them, so a result post would only fail permanently. Skip the queue.
    if (puzzleId.startsWith(kStarterPuzzlePrefix)) return;
    await enqueueMutation(
      PendingMutationData(
        id: _uuid.v4(),
        endpoint: '/puzzles/$puzzleId/result',
        method: 'POST',
        payloadJson: jsonEncode({
          'score': score,
          'completedAt': completedAt,
          if (level != null) 'level': level,
        }),
        idempotencyKey: puzzleId,
        kind: kPuzzleResultKind,
        createdAt: completedAt,
      ),
    );
  }
}
