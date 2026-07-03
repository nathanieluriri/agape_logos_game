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
    // Guarantee a *playable* first puzzle. The cache can hold only encrypted
    // puzzles that cannot be decrypted yet (a fresh install before the answer
    // key is fetched, or a dead backend). Those still count as "unplayed" but
    // cannot be shown, so gating on the row count alone would strand a new
    // player on an empty pond. Seed the bundled plaintext starter pack whenever
    // nothing playable is available.
    if (!await _hasPlayablePuzzle()) {
      // Bundled starter answers are plaintext (offline last resort).
      final starter = await _seed.load();
      if (starter.isNotEmpty) await _insert(starter, encrypted: false);
    }
  }

  /// Whether the cache holds a puzzle the player can actually start right now:
  /// any plaintext puzzle, or (when the answer key is available) any encrypted
  /// one. Encrypted puzzles with no key yet do not count: the read seam cannot
  /// decrypt them, so they would show as an empty pond.
  Future<bool> _hasPlayablePuzzle() async {
    if (await db.cachedPuzzlesDao.unplayedPlaintextCount() > 0) return true;
    if (await db.cachedPuzzlesDao.unplayedCount() == 0) return false;
    // Only encrypted puzzles remain; playable only if the key is obtainable.
    return await _answerKey() != null;
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
        if (!row.encrypted) return puzzleFromRow(row);
        final decrypted = await _decryptAnswers(puzzleFromRow(row));
        if (decrypted != null) return decrypted;
        // The front puzzle is encrypted but not yet decryptable (the per-user
        // answer key has not reached this device). Don't strand the player on
        // an empty pond: serve the first playable plaintext puzzle (the bundled
        // starter pack). Once the key arrives, the encrypted puzzles sort ahead
        // again and play resumes automatically.
        final fallback = await db.cachedPuzzlesDao.firstUnplayedPlaintext();
        return fallback == null ? null : puzzleFromRow(fallback);
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
