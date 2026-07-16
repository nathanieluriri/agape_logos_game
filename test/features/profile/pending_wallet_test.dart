import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:agape_logos_game/features/profile/data/pending_wallet.dart';
import 'package:agape_logos_game/features/puzzles/puzzles_config.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> enqueue(
    String id, {
    String kind = kPuzzleResultKind,
    String payload = '{"score":10}',
  }) {
    return db.pendingMutationsDao.enqueue(
      PendingMutationsCompanion.insert(
        id: id,
        endpoint: '/puzzles/$id/result',
        method: 'POST',
        payloadJson: payload,
        idempotencyKey: id,
        kind: kind,
        createdAt: 1,
      ),
    );
  }

  test('empty queue yields a zero delta', () async {
    expect(await pendingCoinDelta(db), 0);
  });

  test('sums coinsForScore over pending AND inFlight puzzle results', () async {
    await enqueue('p1', payload: '{"score":58}'); // pending
    await enqueue('p2', payload: '{"score":20}');
    await db.pendingMutationsDao.claim('p2'); // inFlight

    expect(
      await pendingCoinDelta(db),
      coinsForScore(58) + coinsForScore(20),
    );
  });

  test('ignores other kinds, synced rows, and failed rows', () async {
    await enqueue('p1', payload: '{"score":58}'); // counted
    await enqueue('l1', kind: 'level_result', payload: '{"score":99}');
    await enqueue('p2', payload: '{"score":40}');
    await db.pendingMutationsDao.markSynced('p2');
    await enqueue('p3', payload: '{"score":30}');
    await db.pendingMutationsDao.markFailed('p3', 'boom');

    expect(await pendingCoinDelta(db), coinsForScore(58));
  });

  test('a malformed payload contributes 0 without throwing', () async {
    await enqueue('bad1', payload: 'not json at all');
    await enqueue('bad2', payload: '[1,2,3]'); // decodes, but not a map
    await enqueue('bad3', payload: '{"score":"high"}'); // score not a num
    await enqueue('ok', payload: '{"score":5}');

    expect(await pendingCoinDelta(db), coinsForScore(5));
  });
}
