import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('enqueue then due() returns the row', () async {
    await db.pendingMutationsDao.enqueue(
      PendingMutationsCompanion.insert(
        id: 'm1',
        endpoint: '/x',
        method: 'POST',
        payloadJson: '{}',
        idempotencyKey: 'k1',
        kind: 'level_result',
        createdAt: 1,
      ),
    );

    final rows = await db.pendingMutationsDao.due(100);
    expect(rows, hasLength(1));
    expect(rows.single.id, 'm1');
    expect(rows.single.status, 'pending');
  });

  test('markSynced removes the row from due()', () async {
    await db.pendingMutationsDao.enqueue(
      PendingMutationsCompanion.insert(
        id: 'm2',
        endpoint: '/x',
        method: 'POST',
        payloadJson: '{}',
        idempotencyKey: 'k2',
        kind: 'level_result',
        createdAt: 1,
      ),
    );
    await db.pendingMutationsDao.markSynced('m2');

    expect(await db.pendingMutationsDao.due(100), isEmpty);
  });
}
