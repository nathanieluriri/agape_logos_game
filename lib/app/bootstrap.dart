import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/logging/app_logger.dart';
import '../core/network/api_client.dart';
import '../core/network/network_providers.dart';
import '../core/offline/offline_providers.dart';
import '../core/offline/sync_engine.dart';
import '../core/offline/sync_scheduler.dart';
import '../core/offline/sync_scheduler_factory.dart';
import '../core/storage/app_database.dart';
import '../core/storage/storage_providers.dart';
import '../features/level_results/data/level_result_repository_impl.dart';
import 'app.dart';

/// Flip to `true` once a real backend [MutationSender] is wired. Until then the
/// app keeps optimistic writes durably queued (pending) and does NOT auto-flush,
/// so nothing is churned to `failed` against a non-existent server.
const bool kBackendSyncEnabled = false;

/// Async app entrypoint: configure logging, open the database, wire the offline
/// sender + reconcilers, and (when enabled) start the platform sync scheduler.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureLogging();

  final AppDatabase db = AppDatabase();

  runZonedGuarded(
    () {
      runApp(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            mutationSenderProvider.overrideWith((ref) {
              final ApiClient api = ref.watch(apiClientProvider);
              return (row) => _send(api, row);
            }),
            mutationReconcilersProvider.overrideWithValue(
              <String, MutationReconciler>{
                // On confirmed sync, flip the cached level result's synced flag.
                kLevelResultKind: (row) =>
                    db.levelResultsDao.markSynced(row.idempotencyKey),
              },
            ),
          ],
          child: const _BootstrapGate(),
        ),
      );
    },
    (Object error, StackTrace stack) =>
        logger.severe('Uncaught zone error', error, stack),
  );
}

/// Placeholder sender - no backend yet. `transient` keeps writes queued (never
/// lost) rather than failing them. Replace with a real ApiClient call.
Future<SendOutcome> _send(ApiClient api, PendingMutation row) async {
  return SendOutcome.transient;
}

class _BootstrapGate extends ConsumerStatefulWidget {
  const _BootstrapGate();

  @override
  ConsumerState<_BootstrapGate> createState() => _BootstrapGateState();
}

class _BootstrapGateState extends ConsumerState<_BootstrapGate> {
  SyncScheduler? _scheduler;

  @override
  void initState() {
    super.initState();
    if (kBackendSyncEnabled) {
      final SyncEngine engine = ref.read(syncEngineProvider);
      _scheduler = createSyncScheduler(engine.flush);
      unawaited(_scheduler!.initialize());
    }
  }

  @override
  void dispose() {
    unawaited(_scheduler?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const AgapeApp();
}
