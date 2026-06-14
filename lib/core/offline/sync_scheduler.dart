/// Triggers queue flushes. Implementations differ by platform; the concrete
/// one is selected via `sync_scheduler_factory.dart` (conditional import).
abstract interface class SyncScheduler {
  /// Wire up triggers (background task on Android; foreground listeners on Web).
  Future<void> initialize();

  /// Request an immediate flush.
  Future<void> requestFlush();
}
