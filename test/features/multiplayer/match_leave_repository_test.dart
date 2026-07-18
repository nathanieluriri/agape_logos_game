import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:agape_logos_game/features/multiplayer/data/match_leave_repository.dart';
import 'package:agape_logos_game/features/multiplayer/domain/multiplayer_config.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('enqueueLeave queues a durable forfeit mutation for the leave endpoint',
      () async {
    final repo = MatchLeaveRepository(db);

    await repo.enqueueLeave('m1');

    final mutations = await db.pendingMutationsDao.due(1000);
    expect(mutations, hasLength(1));
    final row = mutations.single;
    expect(row.endpoint, '/matches/m1/leave');
    expect(row.method, 'POST');
    expect(row.kind, kMatchLeaveKind);
    // Stable per forfeit so a retry dedupes rather than firing twice.
    expect(row.idempotencyKey, 'leave:m1');
    expect(row.payloadJson, '{}');
  });

  test('re-forfeiting the same match reuses the stable idempotency key',
      () async {
    final repo = MatchLeaveRepository(db);

    await repo.enqueueLeave('m1');
    await repo.enqueueLeave('m1');

    // Each call queues a distinct row, but the server-dedupe key is stable so a
    // replayed leave never double-finalizes.
    final mutations = await db.pendingMutationsDao.due(1000);
    expect(mutations, hasLength(2));
    expect(mutations.every((m) => m.idempotencyKey == 'leave:m1'), isTrue);
    expect(mutations.map((m) => m.id).toSet(), hasLength(2));
  });
}
