import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_providers.dart';
import '../data/level_result_repository_impl.dart';
import '../domain/level_result.dart';
import '../domain/level_result_repository.dart';

final levelResultRepositoryProvider = Provider<LevelResultRepository>(
  (ref) => LevelResultRepositoryImpl(ref.watch(appDatabaseProvider)),
);

/// Reactive list of local level results as an `AsyncValue`.
final levelResultsProvider = StreamProvider<List<LevelResult>>(
  (ref) => ref.watch(levelResultRepositoryProvider).watchAll(),
);
