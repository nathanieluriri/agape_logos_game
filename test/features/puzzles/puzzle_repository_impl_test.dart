import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:agape_logos_game/features/puzzles/data/puzzle_repository_impl.dart';
import 'package:agape_logos_game/features/puzzles/data/puzzle_remote.dart';
import 'package:agape_logos_game/features/puzzles/data/puzzle_seed.dart';
import 'package:agape_logos_game/features/puzzles/domain/puzzle.dart';
import 'package:agape_logos_game/features/puzzles/puzzles_config.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// A signed-in user's answer key. Drawn/recovered puzzles cache as encrypted;
/// with a key on hand they count as playable, so the starter-pack fallback (a
/// stopgap for the no-key / offline case) stays out of these draw/refill tests.
final _key = List<int>.generate(32, (i) => i + 1);

/// Two defined answers so plaintext seed puzzles clear the read-seam guard
/// (`guardDefinedAnswers` drops undefined words and skips a puzzle left with
/// fewer than `kMinPlayableAnswers`). Ignored for encrypted inserts, which are
/// vetted only after decryption.
Puzzle _p(String key, String tier) => Puzzle(
      tier: tier, rackSize: key.length, letters: key.split(''),
      letterKey: key, anchor: key,
      answers: const [
        PuzzleAnswer(word: 'ONE', length: 3, definition: 'the first number'),
        PuzzleAnswer(word: 'TWO', length: 3, definition: 'the second number'),
      ],
      answerCount: 2,
    );

/// Test double so seed-fallback tests never touch rootBundle.
class _FakeSeed implements PuzzleSeedSource {
  _FakeSeed([this.puzzles = const []]);
  final List<Puzzle> puzzles;
  int loadCalls = 0;

  @override
  Future<List<Puzzle>> load() async {
    loadCalls++;
    return puzzles;
  }
}

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
    final repo = PuzzleRepositoryImpl(db, remote, answerKey: () async => _key);

    await repo.ensureCacheReady();

    expect(remote.assignedCalls, 1); // recovery attempted first
    // Two-phase draw: recovery empty -> small first draw, then (still under
    // the refill threshold) the full top-up draw. The fake returns the same
    // rows twice; insertOrIgnore keeps the cache at 2.
    expect(remote.drawCalls, 2);
    expect(await db.cachedPuzzlesDao.unplayedCount(), 2);
  });

  test('cold start uses recovered puzzles and still tops up under threshold', () async {
    final remote = _FakeRemote(
      assignedResult: [_p('AAA', 'easy')],
      drawResult: [_p('BBB', 'medium')],
    );
    final repo = PuzzleRepositoryImpl(db, remote, answerKey: () async => _key);

    await repo.ensureCacheReady();

    // recovered 1 (< threshold) so a draw still fires to refill.
    expect(remote.assignedCalls, 1);
    expect(remote.drawCalls, 1);
    expect(await db.cachedPuzzlesDao.unplayedCount(), 2);
  });

  test('no refill when already at/above threshold', () async {
    // Seed >= kRefillThreshold unplayed rows.
    final remote = _FakeRemote(drawResult: [_p('X', 'easy')]);
    final repo = PuzzleRepositoryImpl(db, remote, answerKey: () async => _key);
    final seed = [
      for (var i = 0; i < kRefillThreshold; i++) _p('P$i', 'easy'),
    ];
    // Insert directly via a first ensureCacheReady with a fat draw, then reset counts.
    final seedRemote = _FakeRemote(assignedResult: seed);
    await PuzzleRepositoryImpl(db, seedRemote, answerKey: () async => _key)
        .ensureCacheReady();
    expect(await db.cachedPuzzlesDao.unplayedCount(), kRefillThreshold);

    await repo.ensureCacheReady();
    expect(remote.assignedCalls, 0); // not empty -> no cold-start recovery
    expect(remote.drawCalls, 0); // at threshold -> no refill
  });

  test(
      'offline failures are swallowed and leave the cache unchanged '
      'when the starter pack is also empty', () async {
    final remote = _FakeRemote(throwOffline: true);
    final seed = _FakeSeed();
    final repo = PuzzleRepositoryImpl(db, remote, seed: seed);
    await repo.ensureCacheReady(); // must not throw
    expect(await db.cachedPuzzlesDao.unplayedCount(), 0);
    expect(seed.loadCalls, 1);
  });

  test(
      'falls back to the bundled starter pack when offline on a fresh '
      'cache, so the game page never spins forever', () async {
    final remote = _FakeRemote(throwOffline: true);
    final seed = _FakeSeed([_p('WORD', 'easy'), _p('GAME', 'easy')]);
    final repo = PuzzleRepositoryImpl(db, remote, seed: seed);

    await repo.ensureCacheReady();

    expect(seed.loadCalls, 1);
    expect(await db.cachedPuzzlesDao.unplayedCount(), 2);
  });

  test('does not touch the starter pack once the cache already has puzzles',
      () async {
    final remote = _FakeRemote(drawResult: [_p('NOW', 'easy')]);
    final seed = _FakeSeed([_p('WORD', 'easy')]);
    final repo = PuzzleRepositoryImpl(db, remote,
        seed: seed, answerKey: () async => _key);

    await repo.ensureCacheReady();

    expect(seed.loadCalls, 0);
    expect(await db.cachedPuzzlesDao.unplayedCount(), 1);
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

  test('recover refreshes the key then ensures a playable puzzle (starter '
      'floor when the backend is unreachable)', () async {
    var keyRefreshed = false;
    // Build the repo with an offline remote (draw throws) and a key refresher.
    // PLAN: the plan snippet named _OfflineRemote/_TestSeed; this file already
    // has equivalent fakes (_FakeRemote(throwOffline: true) and _FakeSeed), so
    // those are reused per the plan's own guidance.
    final repo = PuzzleRepositoryImpl(
      db,
      _FakeRemote(throwOffline: true),
      seed: _FakeSeed([_p('${kStarterPuzzlePrefix}WORD', 'easy')]),
      answerKey: () async => null, // no key available
      keyRefresh: () async {
        keyRefreshed = true;
      },
    );

    await repo.recover();

    expect(keyRefreshed, isTrue);
    // A playable (plaintext starter) puzzle is now the front of the stream.
    final puzzle = await repo.watchCurrentPuzzle().first;
    expect(puzzle, isNotNull);
  });

  test('starter puzzle results complete locally and skip the sync queue',
      () async {
    final repo = PuzzleRepositoryImpl(db, _FakeRemote(), seed: _FakeSeed());
    await db.cachedPuzzlesDao.insertAll([
      puzzleToCompanionForTest('${kStarterPuzzlePrefix}easy-01', 'easy'),
    ]);

    await repo.recordPuzzleResult('${kStarterPuzzlePrefix}easy-01', 10, 7);

    expect(await db.cachedPuzzlesDao.unplayedCount(), 0);
    expect(await db.pendingMutationsDao.due(1000), isEmpty);
  });
}

// Local helper so the test does not import the mappers file directly.
CachedPuzzlesCompanion puzzleToCompanionForTest(String key, String tier) =>
    CachedPuzzlesCompanion.insert(
      puzzleId: key, tier: tier, tierRank: 0, rackSize: key.length,
      lettersJson: '[]', anchor: key, answersJson: '[]', answerCount: 0,
      orderIndex: 0, assignedAt: 0,
    );
