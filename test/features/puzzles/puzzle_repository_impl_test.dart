import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:agape_logos_game/features/puzzles/data/puzzle_repository_impl.dart';
import 'package:agape_logos_game/features/puzzles/data/puzzle_remote.dart';
import 'package:agape_logos_game/features/puzzles/domain/puzzle.dart';
import 'package:agape_logos_game/features/puzzles/puzzles_config.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Puzzle _p(String key, String tier) => Puzzle(
      tier: tier, rackSize: key.length, letters: key.split(''),
      letterKey: key, anchor: key,
      answers: const [], answerCount: 0,
    );

class _FakeRemote implements PuzzleRemote {
  _FakeRemote({this.drawResult = const [], this.assignedResult = const [], this.throwOffline = false});
  List<Puzzle> drawResult;
  List<Puzzle> assignedResult;
  bool throwOffline;
  int drawCalls = 0;
  int assignedCalls = 0;

  @override
  Future<List<Puzzle>> draw(Map<String, int> composition) async {
    drawCalls++;
    if (throwOffline) {
      throw DioException(requestOptions: RequestOptions(path: '/puzzles/draw'), type: DioExceptionType.connectionError);
    }
    return drawResult;
  }

  @override
  Future<List<Puzzle>> assignedIncomplete() async {
    assignedCalls++;
    if (throwOffline) {
      throw DioException(requestOptions: RequestOptions(path: '/puzzles/assigned'), type: DioExceptionType.connectionError);
    }
    return assignedResult;
  }
}

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('cold start recovers first, then draws when recovery is empty', () async {
    final remote = _FakeRemote(assignedResult: [], drawResult: [_p('NOW', 'easy'), _p('CAT', 'easy')]);
    final repo = PuzzleRepositoryImpl(db, remote);

    await repo.ensureCacheReady();

    expect(remote.assignedCalls, 1); // recovery attempted first
    expect(remote.drawCalls, 1); // recovery empty -> draw
    expect(await db.cachedPuzzlesDao.unplayedCount(), 2);
  });

  test('cold start uses recovered puzzles and still tops up under threshold', () async {
    final remote = _FakeRemote(
      assignedResult: [_p('AAA', 'easy')],
      drawResult: [_p('BBB', 'medium')],
    );
    final repo = PuzzleRepositoryImpl(db, remote);

    await repo.ensureCacheReady();

    // recovered 1 (< threshold) so a draw still fires to refill.
    expect(remote.assignedCalls, 1);
    expect(remote.drawCalls, 1);
    expect(await db.cachedPuzzlesDao.unplayedCount(), 2);
  });

  test('no refill when already at/above threshold', () async {
    // Seed >= kRefillThreshold unplayed rows.
    final remote = _FakeRemote(drawResult: [_p('X', 'easy')]);
    final repo = PuzzleRepositoryImpl(db, remote);
    final seed = [
      for (var i = 0; i < kRefillThreshold; i++) _p('P$i', 'easy'),
    ];
    // Insert directly via a first ensureCacheReady with a fat draw, then reset counts.
    final seedRemote = _FakeRemote(assignedResult: seed);
    await PuzzleRepositoryImpl(db, seedRemote).ensureCacheReady();
    expect(await db.cachedPuzzlesDao.unplayedCount(), kRefillThreshold);

    await repo.ensureCacheReady();
    expect(remote.assignedCalls, 0); // not empty -> no cold-start recovery
    expect(remote.drawCalls, 0); // at threshold -> no refill
  });

  test('offline failures are swallowed and leave the cache unchanged', () async {
    final remote = _FakeRemote(throwOffline: true);
    final repo = PuzzleRepositoryImpl(db, remote);
    await repo.ensureCacheReady(); // must not throw
    expect(await db.cachedPuzzlesDao.unplayedCount(), 0);
  });

  test('recordPuzzleResult marks completed locally and enqueues the right mutation', () async {
    final remote = _FakeRemote();
    final repo = PuzzleRepositoryImpl(db, remote);
    await db.cachedPuzzlesDao.insertAll([
      puzzleToCompanionForTest('NOW', 'easy'),
    ]);

    await repo.recordPuzzleResult('NOW', 50, 7);

    expect(await db.cachedPuzzlesDao.unplayedCount(), 0); // marked completed
    final mutations = await db.pendingMutationsDao.due(1000);
    expect(mutations.single.kind, kPuzzleResultKind);
    expect(mutations.single.idempotencyKey, 'NOW');
    expect(mutations.single.endpoint, '/puzzles/NOW/result');
    expect(mutations.single.payloadJson, contains('"score":50'));
  });
}

// Local helper so the test does not import the mappers file directly.
CachedPuzzlesCompanion puzzleToCompanionForTest(String key, String tier) =>
    CachedPuzzlesCompanion.insert(
      puzzleId: key, tier: tier, tierRank: 0, rackSize: key.length,
      lettersJson: '[]', anchor: key, answersJson: '[]', answerCount: 0,
      orderIndex: 0, assignedAt: 0,
    );
