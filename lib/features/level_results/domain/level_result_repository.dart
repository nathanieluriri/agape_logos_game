import 'level_result.dart';

/// Contract for recording and observing level results.
abstract interface class LevelResultRepository {
  /// Optimistic: applies locally immediately and enqueues the sync.
  /// Must not throw when offline.
  Future<void> recordCompletion(LevelResult result);

  /// Reactive local view (the UI source of truth).
  Stream<List<LevelResult>> watchAll();
}
