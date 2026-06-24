import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:agape_logos_game/core/storage/storage_providers.dart';
import 'package:agape_logos_game/features/puzzles/application/puzzle_providers.dart';
import 'package:agape_logos_game/features/puzzles/data/puzzle_remote.dart';
import 'package:agape_logos_game/features/puzzles/domain/puzzle.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRemote implements PuzzleRemote {
  @override
  Future<List<Puzzle>> draw(Map<String, int> c) async => const [];
  @override
  Future<List<Puzzle>> assignedIncomplete() async => const [];
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      puzzleRemoteProvider.overrideWithValue(_FakeRemote()),
    ]);
  });
  tearDown(() {
    container.dispose();
    db.close();
  });

  test('currentPuzzleProvider emits the next unplayed puzzle', () async {
    await db.cachedPuzzlesDao.insertAll([
      CachedPuzzlesCompanion.insert(
        puzzleId: 'NOW', tier: 'easy', tierRank: 0, rackSize: 3,
        lettersJson: '["N","O","W"]', anchor: 'NOW',
        answersJson: '[]', answerCount: 0, orderIndex: 0, assignedAt: 0,
      ),
    ]);
    // Activate the StreamProvider so its future resolves under the test binding.
    final sub = container.listen(currentPuzzleProvider, (_, __) {});
    final puzzle = await container.read(currentPuzzleProvider.future);
    sub.close();
    expect(puzzle!.letterKey, 'NOW');
  });

  test('controller.recordResult marks completed and enqueues a mutation', () async {
    await db.cachedPuzzlesDao.insertAll([
      CachedPuzzlesCompanion.insert(
        puzzleId: 'CAT', tier: 'easy', tierRank: 0, rackSize: 3,
        lettersJson: '[]', anchor: 'CAT', answersJson: '[]', answerCount: 0,
        orderIndex: 0, assignedAt: 0,
      ),
    ]);
    await container.read(puzzleControllerProvider).recordResult('CAT', 10, 3);
    expect(await db.cachedPuzzlesDao.unplayedCount(), 0);
    final mutations = await db.pendingMutationsDao.due(1000);
    expect(mutations.single.idempotencyKey, 'CAT');
  });
}
