import '../storage/app_database.dart';
import 'mutation.dart';

/// Mixin for repositories that perform optimistic writes. Provides one helper:
/// persist a mutation into the durable queue for later sync.
mixin OfflineAwareRepository {
  AppDatabase get db;

  Future<void> enqueueMutation(PendingMutationData m) {
    return db.pendingMutationsDao.enqueue(
      PendingMutationsCompanion.insert(
        id: m.id,
        endpoint: m.endpoint,
        method: m.method,
        payloadJson: m.payloadJson,
        idempotencyKey: m.idempotencyKey,
        kind: m.kind,
        createdAt: m.createdAt,
      ),
    );
  }
}
