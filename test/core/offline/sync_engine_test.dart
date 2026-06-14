import 'package:agape_logos_game/core/connectivity/connectivity_service.dart';
import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:agape_logos_game/core/offline/sync_engine.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _AlwaysOnline extends ConnectivityService {
  @override
  Future<bool> get isOnline async => true;
}

class _AlwaysOffline extends ConnectivityService {
  @override
  Future<bool> get isOnline async => false;
}

Future<void> _enqueue(AppDatabase db, String id) {
  return db.pendingMutationsDao.enqueue(
    PendingMutationsCompanion.insert(
      id: id,
      endpoint: '/x',
      method: 'POST',
      payloadJson: '{}',
      idempotencyKey: id,
      kind: 'k',
      createdAt: 0,
    ),
  );
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('success marks synced and runs the reconciler', () async {
    await _enqueue(db, 'm1');
    var reconciled = false;
    final engine = SyncEngine(
      db: db,
      connectivity: _AlwaysOnline(),
      sender: (_) async => SendOutcome.success,
      reconcilers: {'k': (_) async => reconciled = true},
      clock: () => 0,
    );

    await engine.flush();

    final row = await db.select(db.pendingMutations).getSingle();
    expect(row.status, 'synced');
    expect(row.lastError, isNull);
    expect(reconciled, isTrue);
  });

  test('offline flush is a no-op', () async {
    await _enqueue(db, 'm0');
    var sent = false;
    final engine = SyncEngine(
      db: db,
      connectivity: _AlwaysOffline(),
      sender: (_) async {
        sent = true;
        return SendOutcome.success;
      },
      clock: () => 0,
    );

    await engine.flush();

    expect(sent, isFalse);
    expect(await db.pendingMutationsDao.due(0), hasLength(1));
  });

  test('single-flight: overlapping flushes send each row once', () async {
    await _enqueue(db, 'm1');
    var sends = 0;
    final engine = SyncEngine(
      db: db,
      connectivity: _AlwaysOnline(),
      sender: (_) async {
        sends++;
        return SendOutcome.success;
      },
      clock: () => 0,
    );

    // Start two flushes back-to-back; the guard must serialize them.
    final f1 = engine.flush();
    final f2 = engine.flush();
    await Future.wait([f1, f2]);

    expect(sends, 1);
  });

  test('transient schedules a retry with exact exponential backoff', () async {
    await _enqueue(db, 'm2');
    final engine = SyncEngine(
      db: db,
      connectivity: _AlwaysOnline(),
      sender: (_) async => SendOutcome.transient,
      clock: () => 0,
    );

    await engine.flush();

    final row = await db.select(db.pendingMutations).getSingle();
    expect(row.retryCount, 1);
    expect(row.nextAttemptAt, 1000); // 1000 * 2^0, clock pinned to 0
    expect(row.status, 'pending');
  });

  test('a thrown sender is treated as transient (retried, not propagated)', () async {
    await _enqueue(db, 'm-throw');
    final engine = SyncEngine(
      db: db,
      connectivity: _AlwaysOnline(),
      sender: (_) async => throw Exception('boom'),
      clock: () => 0,
    );

    await engine.flush(); // must not throw

    final row = await db.select(db.pendingMutations).getSingle();
    expect(row.retryCount, 1);
    expect(row.status, 'pending');
  });

  test('permanent marks failed', () async {
    await _enqueue(db, 'm3');
    final engine = SyncEngine(
      db: db,
      connectivity: _AlwaysOnline(),
      sender: (_) async => SendOutcome.permanent,
      clock: () => 0,
    );

    await engine.flush();

    final row = await db.select(db.pendingMutations).getSingle();
    expect(row.status, 'failed');
    expect(row.lastError, 'permanent failure');
  });

  test('exceeding maxRetries transitions to failed', () async {
    await _enqueue(db, 'm4');
    var now = 0;
    final engine = SyncEngine(
      db: db,
      connectivity: _AlwaysOnline(),
      sender: (_) async => SendOutcome.transient,
      clock: () => now,
      maxRetries: 1,
    );

    await engine.flush(); // attempt 1 -> retryCount 1, nextAttemptAt 1000, pending
    var row = await db.select(db.pendingMutations).getSingle();
    expect(row.status, 'pending');
    expect(row.retryCount, 1);

    now = 5000; // advance past the backoff gate
    await engine.flush(); // attempt 2 -> 2 > maxRetries(1) -> failed
    row = await db.select(db.pendingMutations).getSingle();
    expect(row.status, 'failed');
    expect(row.lastError, 'max retries exceeded');
  });

  test('reconciler does NOT run on transient or permanent outcomes', () async {
    var reconciled = false;
    final reconcilers = {'k': (PendingMutation _) async => reconciled = true};

    await _enqueue(db, 't1');
    await SyncEngine(
      db: db,
      connectivity: _AlwaysOnline(),
      sender: (_) async => SendOutcome.transient,
      reconcilers: reconcilers,
      clock: () => 0,
    ).flush();
    expect(reconciled, isFalse);

    await db.pendingMutationsDao.enqueue(
      PendingMutationsCompanion.insert(
        id: 'p1', endpoint: '/x', method: 'POST', payloadJson: '{}',
        idempotencyKey: 'p1', kind: 'k', createdAt: 0,
      ),
    );
    await SyncEngine(
      db: db,
      connectivity: _AlwaysOnline(),
      sender: (_) async => SendOutcome.permanent,
      reconcilers: reconcilers,
      clock: () => 0,
    ).flush();
    expect(reconciled, isFalse);
  });
}
