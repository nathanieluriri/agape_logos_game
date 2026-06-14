import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_providers.dart';
import '../data/level_result_repository_impl.dart';
import '../domain/level_result.dart';
import '../domain/level_result_repository.dart';

final levelResultRepositoryProvider = Provider<LevelResultRepository>(
  (ref) => LevelResultRepositoryImpl(ref.watch(appDatabaseProvider)),
);

/// Reactive list of local level results as an `AsyncValue`. autoDispose so the
/// drift query stream is cancelled when the screen stops watching it.
final levelResultsProvider = StreamProvider.autoDispose<List<LevelResult>>(
  (ref) => ref.watch(levelResultRepositoryProvider).watchAll(),
);
