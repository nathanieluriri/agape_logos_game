import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:agape_logos_game/features/level_results/data/level_result_repository_impl.dart';
import 'package:agape_logos_game/features/level_results/domain/level_result.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('recordCompletion applies locally and enqueues a mutation', () async {
    final repo = LevelResultRepositoryImpl(db);

    await repo.recordCompletion(
      const LevelResult(id: 'r1', levelId: 3, score: 100, completedAt: 5),
    );

    // Local apply is immediate (UI source of truth).
    final results = await repo.watchAll().first;
    expect(results.single.id, 'r1');
    expect(results.single.synced, isFalse);

    // A sync mutation was queued with the right kind + idempotency key.
    final mutations = await db.pendingMutationsDao.due(1000);
    expect(mutations.single.kind, kLevelResultKind);
    expect(mutations.single.idempotencyKey, 'r1');
  });
}
