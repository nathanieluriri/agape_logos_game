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

/// Fire-and-forget "sync now" seam for features that just enqueued a mutation
/// (e.g. a level win). Defaults to a no-op so tests and previews need no sync
/// wiring; `bootstrap()` overrides it with the real engine flush. Callers
/// don't await it: delivery failures simply re-arm the engine's backoff.
final syncKickProvider = Provider<Future<void> Function()>(
  (ref) => () async {},
);
