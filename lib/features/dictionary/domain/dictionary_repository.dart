import 'dictionary_entry.dart';

/// The player's solved-word dictionary. `GET /me/dictionary` is a CachedRead:
/// fetch online with write-through to Drift, serve the cache offline. Mirrors
/// the shape of ProfileRepository (fetch + watch).
abstract class DictionaryRepository {
  /// Fetches the dictionary for [uid] (online, write-through). On offline /
  /// transient errors, serves the cached list. Never throws for connectivity.
  Future<List<DictionaryEntry>> fetch(String uid);

  /// Reactive stream of [uid]'s cached dictionary (updates as fetch writes
  /// through). Empty until the first successful fetch.
  Stream<List<DictionaryEntry>> watch(String uid);
}
