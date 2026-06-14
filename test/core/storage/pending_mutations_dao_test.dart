import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> enqueue(String id, {int createdAt = 1}) {
    return db.pendingMutationsDao.enqueue(
      PendingMutationsCompanion.insert(
        id: id,
        endpoint: '/x',
        method: 'POST',
        payloadJson: '{}',
        idempotencyKey: id,
        kind: 'level_result',
        createdAt: createdAt,
      ),
    );
  }

  test('enqueue then due() returns the row', () async {
    await enqueue('m1');
    final rows = await db.pendingMutationsDao.due(100);
    expect(rows, hasLength(1));
    expect(rows.single.id, 'm1');
    expect(rows.single.status, 'pending');
  });

  test('markSynced sets status synced (durable) and excludes it from due()', () async {
    await enqueue('m2');
    await db.pendingMutationsDao.markSynced('m2');

    // The row is NOT deleted — the queue is durable/inspectable.
    final row = await (db.select(db.pendingMutations)
          ..where((t) => t.id.equals('m2')))
        .getSingle();
    expect(row.status, 'synced');
    expect(await db.pendingMutationsDao.due(100), isEmpty);
  });

  test('claim marks a pending row in-flight and reports it claimed', () async {
    await enqueue('c1');
    expect(await db.pendingMutationsDao.claim('c1'), 1);
    final row = await (db.select(db.pendingMutations)
          ..where((t) => t.id.equals('c1')))
        .getSingle();
    expect(row.status, 'inFlight');
    // A synced row can no longer be claimed.
    await db.pendingMutationsDao.markSynced('c1');
    expect(await db.pendingMutationsDao.claim('c1'), 0);
  });

  test('due() gates on nextAttemptAt (backoff) and excludes failed', () async {
    await enqueue('g1');
    await db.pendingMutationsDao.scheduleRetry('g1', 1, 500);
    expect(await db.pendingMutationsDao.due(499), isEmpty); // not yet due
    expect(await db.pendingMutationsDao.due(500), hasLength(1)); // <= boundary

    await db.pendingMutationsDao.markFailed('g1', 'x');
    expect(await db.pendingMutationsDao.due(10000), isEmpty);
  });

  test('due() includes inFlight rows (crash recovery)', () async {
    await enqueue('i1');
    await db.pendingMutationsDao.claim('i1'); // -> inFlight
    final rows = await db.pendingMutationsDao.due(100);
    expect(rows.single.id, 'i1');
    expect(rows.single.status, 'inFlight');
  });

  test('due() returns rows in createdAt (FIFO) order', () async {
    await enqueue('b', createdAt: 3);
    await enqueue('a', createdAt: 1);
    await enqueue('c', createdAt: 2);
    final ids = (await db.pendingMutationsDao.due(100)).map((r) => r.id).toList();
    expect(ids, ['a', 'c', 'b']);
  });

  test('scheduleRetry resets a claimed row back to pending', () async {
    await enqueue('r1');
    await db.pendingMutationsDao.claim('r1'); // inFlight
    await db.pendingMutationsDao.scheduleRetry('r1', 2, 0);
    final row = await (db.select(db.pendingMutations)
          ..where((t) => t.id.equals('r1')))
        .getSingle();
    expect(row.status, 'pending');
    expect(row.retryCount, 2);
  });
}
