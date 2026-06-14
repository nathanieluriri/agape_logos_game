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
import 'app.dart';

/// Async app entrypoint: configure logging, open the database, wire the
/// offline sender, and start the platform sync scheduler.
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
          ],
          child: const _BootstrapGate(),
        ),
      );
    },
    (Object error, StackTrace stack) =>
        logger.severe('Uncaught zone error', error, stack),
  );
}

/// Real endpoints don't exist yet. Treat sends as a permanent no-op so the
/// local-first write still succeeds and the queue doesn't spin. Replace with a
/// real `ApiClient` call once the backend lands.
Future<SendOutcome> _send(ApiClient api, PendingMutation row) async {
  return SendOutcome.permanent;
}

class _BootstrapGate extends ConsumerStatefulWidget {
  const _BootstrapGate();

  @override
  ConsumerState<_BootstrapGate> createState() => _BootstrapGateState();
}

class _BootstrapGateState extends ConsumerState<_BootstrapGate> {
  @override
  void initState() {
    super.initState();
    final SyncEngine engine = ref.read(syncEngineProvider);
    final SyncScheduler scheduler = createSyncScheduler(engine.flush);
    unawaited(scheduler.initialize());
  }

  @override
  Widget build(BuildContext context) => const AgapeApp();
}
