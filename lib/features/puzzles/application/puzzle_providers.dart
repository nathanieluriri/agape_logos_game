import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../data/puzzle_remote.dart';
import '../data/puzzle_repository_impl.dart';
import '../domain/puzzle.dart';
import '../domain/puzzle_repository.dart';

final puzzleRemoteProvider = Provider<PuzzleRemote>(
  (ref) => HttpPuzzleRemote(ref.watch(apiClientProvider)),
);

final puzzleRepositoryProvider = Provider<PuzzleRepository>(
  (ref) => PuzzleRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(puzzleRemoteProvider),
  ),
);

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
  Future<void> recordResult(String puzzleId, int score, int completedAt) =>
      _repo.recordPuzzleResult(puzzleId, score, completedAt);
}

final puzzleControllerProvider = Provider<PuzzleController>(
  (ref) => PuzzleController(ref.watch(puzzleRepositoryProvider)),
);
