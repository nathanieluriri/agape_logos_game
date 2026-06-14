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

    expect(await db.pendingMutationsDao.due(0), isEmpty);
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

  test('transient schedules a retry with backoff', () async {
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
    expect(row.nextAttemptAt, greaterThan(0));
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
  });
}
