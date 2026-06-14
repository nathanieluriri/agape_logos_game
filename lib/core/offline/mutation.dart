/// Lifecycle of a queued mutation.
enum MutationStatus { pending, inFlight, synced, failed }

/// Plain transfer object a repository hands to the offline queue when it wants
/// a write replayed against the server later.
class PendingMutationData {
  const PendingMutationData({
    required this.id,
    required this.endpoint,
    required this.method,
    required this.payloadJson,
    required this.idempotencyKey,
    required this.kind,
    required this.createdAt,
  });

  final String id;
  final String endpoint;
  final String method;
  final String payloadJson;

  /// Sent as a header so the server can dedupe replays safely.
  final String idempotencyKey;

  /// Logical mutation type; routes reconciliation/compensation by handler.
  final String kind;
  final int createdAt;
}
