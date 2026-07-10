import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'pending_mutations_dao.g.dart';

@DriftAccessor(tables: [PendingMutations])
class PendingMutationsDao extends DatabaseAccessor<AppDatabase>
    with _$PendingMutationsDaoMixin {
  PendingMutationsDao(super.db);

  Future<void> enqueue(PendingMutationsCompanion row) =>
      into(pendingMutations).insert(row);

  /// Rows eligible to be sent now: pending/in-flight and past their backoff gate.
  Future<List<PendingMutation>> due(int now) {
    return (select(pendingMutations)
          ..where((t) => t.status.isIn(const ['pending', 'inFlight']))
          ..where((t) => t.nextAttemptAt.isSmallerOrEqualValue(now))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .get();
  }

  /// Atomically marks a row in-flight before sending. Returns the number of
  /// rows updated (1 = claimed). Accepts already-`inFlight` rows so a row left
  /// in-flight by a crash is re-claimable on the next flush. Cross-isolate
  /// double-send is made safe by the mutation's idempotency key.
  Future<int> claim(String id) =>
      (update(pendingMutations)
            ..where(
              (t) => t.id.equals(id) & t.status.isIn(const ['pending', 'inFlight']),
            ))
          .write(const PendingMutationsCompanion(status: Value('inFlight')));

  Future<void> markSynced(String id) =>
      (update(pendingMutations)..where((t) => t.id.equals(id)))
          .write(const PendingMutationsCompanion(status: Value('synced')));

  Future<void> markFailed(String id, String error) =>
      (update(pendingMutations)..where((t) => t.id.equals(id))).write(
        PendingMutationsCompanion(
          status: const Value('failed'),
          lastError: Value(error),
        ),
      );

  Future<void> scheduleRetry(String id, int retryCount, int nextAttemptAt) =>
      (update(pendingMutations)..where((t) => t.id.equals(id))).write(
        PendingMutationsCompanion(
          status: const Value('pending'),
          retryCount: Value(retryCount),
          nextAttemptAt: Value(nextAttemptAt),
        ),
      );

  /// Watches permanently-failed rows of [kind] (max retries exhausted or a
  /// non-retryable 4xx). Used to surface a "progress didn't save" notice only
  /// when the cloud will never learn about a local completion.
  Stream<List<PendingMutation>> watchFailed(String kind) =>
      (select(pendingMutations)
            ..where((t) => t.status.equals('failed') & t.kind.equals(kind)))
          .watch();

  /// Re-arms failed rows of [kind] for another attempt (user tapped Retry):
  /// status -> pending, retryCount -> 0, nextAttemptAt -> 0.
  Future<void> resetFailed(String kind) =>
      (update(pendingMutations)
            ..where((t) => t.status.equals('failed') & t.kind.equals(kind)))
          .write(
        const PendingMutationsCompanion(
          status: Value('pending'),
          retryCount: Value(0),
          nextAttemptAt: Value(0),
        ),
      );
}
