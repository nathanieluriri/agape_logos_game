import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/dictionary_remote.dart';
import '../data/dictionary_repository_impl.dart';
import '../domain/dictionary_entry.dart';
import '../domain/dictionary_repository.dart';

final dictionaryRemoteProvider = Provider<DictionaryRemote>(
  (ref) => HttpDictionaryRemote(ref.watch(apiClientProvider)),
);

final dictionaryRepositoryProvider = Provider<DictionaryRepository>(
  (ref) => DictionaryRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(dictionaryRemoteProvider),
  ),
);

/// Reactive display source: the signed-in user's cached dictionary, streamed
/// from Drift. Empty stream when signed out. Updates as [dictionaryRefreshProvider]
/// writes through.
final dictionaryEntriesProvider =
    StreamProvider.autoDispose<List<DictionaryEntry>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream<List<DictionaryEntry>>.value(const []);
  }
  return ref.watch(dictionaryRepositoryProvider).watch(user.uid);
});

/// Fires the network fetch (write-through). The dictionary page watches this
/// only to show a first-load spinner / error while the cache is still empty;
/// once the cache has rows the stream drives the UI. `fetch` never throws for
/// connectivity (it falls back to cache), so this rarely errors.
final dictionaryRefreshProvider = FutureProvider.autoDispose<void>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return;
  await ref.watch(dictionaryRepositoryProvider).fetch(user.uid);
});
