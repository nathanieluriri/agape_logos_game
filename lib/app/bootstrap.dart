import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/audio/audio_providers.dart';
import '../core/audio/audio_service.dart';
import '../core/haptics/haptic_providers.dart';
import '../core/haptics/haptic_service.dart';
import '../core/haptics/haptics.dart';
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
import '../features/auth/domain/auth_user.dart';
import '../features/profile/application/profile_providers.dart';
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

  // Navigation is imperative (context.push / pushReplacement everywhere). By
  // default go_router does NOT update the browser address bar for imperative
  // calls, so on web the URL stayed on "/" no matter which screen was open.
  // Opting in makes the address bar (and back/forward history) track the route.
  GoRouter.optionURLReflectsImperativeAPIs = true;

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final AppDatabase db = AppDatabase();

  // Restore the persisted mute state so audio honors the saved Sound setting
  // from the first frame. Best-effort: a read failure (e.g. web before the
  // Drift WASM runtime is added) leaves audio unmuted rather than crashing.
  final FlameAudioService audio = FlameAudioService();
  final FlutterHapticService haptics = FlutterHapticService();
  try {
    final settings = await db.gameSettingsDao.watch().first;
    audio.setMuted(!settings.soundEffects);
    haptics.setMuted(!settings.haptics);
  } catch (e, s) {
    logger.warning('Could not restore sound setting', e, s);
  }
  // Share the (mute-restored) instance with the ambient holder the provider-free
  // pond buttons call, then probe haptic capabilities up front so the first
  // button tap does not pay for the platform-channel round trip. Best-effort:
  // never blocks bootstrap.
  Haptics.instance = haptics;
  unawaited(haptics.init());

  runZonedGuarded(
    () {
      runApp(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            audioServiceProvider.overrideWithValue(audio),
            hapticServiceProvider.overrideWithValue(haptics),
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
  Widget build(BuildContext context) {
    // Provision and cache the server profile whenever the signed-in account
    // changes. Fires for every sign-in method (Google, email, guest) and on a
    // restored session; the first GET /me creates the server document. On
    // sign-out (uid -> null) the cached profile is dropped.
    ref.listen<AsyncValue<AuthUser?>>(authStateProvider, (prev, next) {
      final String? uid = next.asData?.value?.uid;
      final String? prevUid = prev?.asData?.value?.uid;
      if (uid == null) {
        if (prevUid != null) {
          unawaited(ref.read(profileControllerProvider.notifier).clear());
        }
      } else if (uid != prevUid) {
        unawaited(
          ref.read(profileControllerProvider.notifier).load(
                uid,
                firebaseDisplayName: next.asData?.value?.displayName,
              ),
        );
        // The startup flush ran before Firebase restored the user, so any
        // offline win mutation was skipped as transient. Now that the user is
        // restored, ask the scheduler to flush so the queue reaches the server.
        unawaited(_scheduler?.requestFlush() ?? Future<void>.value());
      }
    });
    return const AgapeApp();
  }
}
