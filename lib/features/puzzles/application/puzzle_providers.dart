import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/crypto/answer_cipher.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/answer_key_store.dart';
import '../data/puzzle_remote.dart';
import '../data/puzzle_repository_impl.dart';
import '../domain/puzzle.dart';
import '../domain/puzzle_repository.dart';

final puzzleRemoteProvider = Provider<PuzzleRemote>(
  (ref) => HttpPuzzleRemote(ref.watch(apiClientProvider)),
);

final answerCipherProvider = Provider<AnswerCipher>((ref) => AnswerCipher());

final answerKeyStoreProvider = Provider<AnswerKeyStore>(
  (ref) => AnswerKeyStore(ref.watch(apiClientProvider)),
);

final puzzleRepositoryProvider = Provider<PuzzleRepository>((ref) {
  // Seed defaults to the bundled starter pack inside the repository.
  final store = ref.watch(answerKeyStoreProvider);
  return PuzzleRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(puzzleRemoteProvider),
    cipher: ref.watch(answerCipherProvider),
    answerKey: () async {
      final user = ref.read(currentUserProvider);
      if (user == null) return null;
      return store.keyFor(user.uid);
    },
    keyRefresh: () async {
      final user = ref.read(currentUserProvider);
      if (user == null) return;
      await store.refresh(user.uid);
    },
  );
});

final currentPuzzleProvider = StreamProvider<Puzzle?>(
  (ref) => ref.watch(puzzleRepositoryProvider).watchCurrentPuzzle(),
);

final remainingCountsProvider = FutureProvider<Map<String, int>>(
  (ref) => ref.watch(puzzleRepositoryProvider).remainingByTier(),
);

/// Thin imperative surface for C2 (the gameplay screen).
class PuzzleController {
  PuzzleController(this._repo);
  final PuzzleRepository _repo;

  Future<void> refresh() => _repo.ensureCacheReady();
  Future<void> recover() => _repo.recover();
  Future<void> recordResult(
    String puzzleId,
    int score,
    int completedAt, {
    int? level,
  }) =>
      _repo.recordPuzzleResult(puzzleId, score, completedAt, level: level);
}

final puzzleControllerProvider = Provider<PuzzleController>(
  (ref) => PuzzleController(ref.watch(puzzleRepositoryProvider)),
);
