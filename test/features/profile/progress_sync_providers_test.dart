import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:agape_logos_game/core/storage/storage_providers.dart';
import 'package:agape_logos_game/features/profile/application/progress_sync_providers.dart';
import 'package:agape_logos_game/features/puzzles/puzzles_config.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });
  tearDown(() {
    container.dispose();
    db.close();
  });

  /// Reads the provider's first value. The StreamProvider must have an active
  /// listener for its future to resolve under the test binding (same pattern as
  /// `test/features/puzzles/puzzle_providers_test.dart`).
  Future<bool> readFailed() async {
    final sub = container.listen(progressSyncFailedProvider, (_, __) {});
    final value = await container.read(progressSyncFailedProvider.future);
    sub.close();
    return value;
  }

  Future<void> enqueue(String id, String kind) {
    return db.pendingMutationsDao.enqueue(
      PendingMutationsCompanion.insert(
        id: id,
        endpoint: '/puzzles/$id/result',
        method: 'POST',
        payloadJson: '{}',
        idempotencyKey: id,
        kind: kind,
        createdAt: 1,
      ),
    );
  }

  test('false when no failed puzzle_result mutations', () async {
    expect(await readFailed(), isFalse);
  });

  test('false when a puzzle_result mutation is merely pending', () async {
    await enqueue('p1', kPuzzleResultKind);
    expect(await readFailed(), isFalse);
  });

  test('true when a puzzle_result mutation is permanently failed', () async {
    await enqueue('p1', kPuzzleResultKind);
    await db.pendingMutationsDao.markFailed('p1', 'boom');
    expect(await readFailed(), isTrue);
  });

  test('false when only a different kind permanently failed', () async {
    await enqueue('L1', 'level_result');
    await db.pendingMutationsDao.markFailed('L1', 'boom');
    expect(await readFailed(), isFalse);
  });

  // Asserted against the DAO stream the provider watches rather than reading
  // `provider.future` twice: a StreamProvider's future resolves once, so a
  // second read can return the cached value before drift re-emits.
  test('resetFailed clears the failed set the provider watches', () async {
    await enqueue('p1', kPuzzleResultKind);
    await db.pendingMutationsDao.markFailed('p1', 'boom');
    final failed = db.pendingMutationsDao.watchFailed(kPuzzleResultKind);
    expect(await failed.first, isNotEmpty);

    await db.pendingMutationsDao.resetFailed(kPuzzleResultKind);
    expect(await failed.first, isEmpty);
  });
}
