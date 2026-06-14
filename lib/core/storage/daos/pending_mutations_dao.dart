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
}
