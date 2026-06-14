import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../connectivity/connectivity_providers.dart';
import '../storage/storage_providers.dart';
import 'sync_engine.dart';

/// Overridden in `bootstrap()` with a real, Dio-backed sender.
final mutationSenderProvider = Provider<MutationSender>(
  (ref) => throw UnimplementedError('mutationSenderProvider must be overridden'),
);

/// Optional per-`kind` reconcilers; features may override to add handlers.
final mutationReconcilersProvider = Provider<Map<String, MutationReconciler>>(
  (ref) => const {},
);

final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine(
    db: ref.watch(appDatabaseProvider),
    connectivity: ref.watch(connectivityServiceProvider),
    sender: ref.watch(mutationSenderProvider),
    reconcilers: ref.watch(mutationReconcilersProvider),
  );
});
