import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../core/offline/mutation.dart';
import '../../../core/offline/offline_aware_repository.dart';
import '../../../core/storage/app_database.dart';
import '../domain/multiplayer_config.dart';

/// Durably queues a match forfeit (`POST /matches/:id/leave`) through the shared
/// optimistic-write + sync-engine mechanism, instead of the old bare
/// fire-and-forget HTTP call that vanished on any offline/403/500 failure and
/// left the match `active` server-side.
///
/// The enqueue is a local write that completes even offline; the sync engine
/// then delivers it with single-flight + exponential backoff and retries once
/// connectivity returns. The server's `leaveMatch` is naturally idempotent
/// (a no-op once the match is already finished/cancelled), and the stable
/// per-match idempotency key dedupes any replay, so a retried leave never
/// double-finalizes.
class MatchLeaveRepository with OfflineAwareRepository {
  MatchLeaveRepository(this.db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  @override
  final AppDatabase db;
  final Uuid _uuid;

  /// Enqueue the forfeit for [matchId]. Completes as soon as the durable row is
  /// written locally (even offline); the sync engine owns delivery + retry.
  Future<void> enqueueLeave(String matchId) {
    return enqueueMutation(
      PendingMutationData(
        id: _uuid.v4(),
        endpoint: '/matches/$matchId/leave',
        method: 'POST',
        payloadJson: jsonEncode(const <String, dynamic>{}),
        // Stable per forfeit so a retry dedupes rather than firing twice.
        idempotencyKey: 'leave:$matchId',
        kind: kMatchLeaveKind,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}
