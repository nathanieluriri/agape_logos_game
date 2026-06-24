import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/audio/audio_providers.dart';
import '../core/audio/audio_service.dart';
import '../core/logging/app_logger.dart';
import '../core/network/network_providers.dart';
import '../core/offline/http_mutation_sender.dart';
import '../core/offline/offline_providers.dart';
import '../core/offline/sync_engine.dart';
import '../core/offline/sync_scheduler.dart';
import '../core/offline/sync_scheduler_factory.dart';
import '../core/storage/app_database.dart';
import '../core/storage/storage_providers.dart';
import '../features/auth/application/auth_providers.dart';
import '../firebase_options.dart';
import 'app.dart';
import 'background_entrypoint.dart';
import 'sync_reconcilers.dart';

/// Foreground sync is live: the real [HttpMutationSender] replays queued
/// optimistic writes against the deployed `api` function when the app is open,
/// online, and signed in.
const bool kBackendSyncEnabled = true;

/// Background (WorkManager isolate) flushing is live: the isolate uses the real
/// HttpMutationSender (see `background_sync.dart`), guards on the restored user,
/// and never registers when signed out.
const bool kBackgroundFlushEnabled = true;

/// Async app entrypoint: configure logging, open the database, wire the offline
/// sender + reconcilers, and (when enabled) start the platform sync scheduler.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureLogging();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final AppDatabase db = AppDatabase();

  // Restore the persisted mute state so audio honors the saved Sound setting
  // from the first frame. Best-effort: a read failure (e.g. web before the
  // Drift WASM runtime is added) leaves audio unmuted rather than crashing.
  final FlameAudioService audio = FlameAudioService();
  try {
    final settings = await db.gameSettingsDao.watch().first;
    audio.setMuted(!settings.soundEffects);
  } catch (e, s) {
    logger.warning('Could not restore sound setting', e, s);
  }

  runZonedGuarded(
    () {
      runApp(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            audioServiceProvider.overrideWithValue(audio),
            // Attach the current user's ID token to outgoing sync requests
            // without core/network importing the auth feature.
            authTokenProvider.overrideWith(
              (ref) => () => ref.read(authRepositoryProvider).idToken(),
            ),
            mutationSenderProvider.overrideWith((ref) {
              final HttpMutationSender sender = HttpMutationSender(
                api: ref.watch(apiClientProvider),
                auth: ref.read(authRepositoryProvider),
              );
              return sender.send;
            }),
            mutationReconcilersProvider.overrideWithValue(
              buildMutationReconcilers(db),
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
      _scheduler = createSyncScheduler(
        engine.flush,
        enableBackground: kBackgroundFlushEnabled,
        backgroundEntryPoint: backgroundFlushEntryPoint,
      );
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
