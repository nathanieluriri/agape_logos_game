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
import '../core/notifications/push_providers.dart';
import '../core/offline/http_mutation_sender.dart';
import '../core/offline/offline_providers.dart';
import '../core/offline/sync_engine.dart';
import '../core/offline/sync_scheduler.dart';
import '../core/offline/sync_scheduler_factory.dart';
import '../core/storage/app_database.dart';
import '../core/storage/storage_providers.dart';
import '../features/auth/application/auth_providers.dart';
import '../features/auth/domain/auth_user.dart';
import '../features/multiplayer/application/resume_providers.dart';
import '../features/multiplayer/presentation/widgets/fog_shader.dart';
import '../features/profile/application/profile_providers.dart';
import '../features/social/application/social_providers.dart';
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

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
  unawaited(warmUpFogShader());

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
              (ref) =>
                  () => ref.read(authRepositoryProvider).idToken(),
            ),
            mutationSenderProvider.overrideWith((ref) {
              final HttpMutationSender sender = HttpMutationSender(
                api: ref.watch(apiClientProvider),
                auth: ref.read(authRepositoryProvider),
              );
              return sender.send;
            }),
            // Give features a real "sync now" kick (no-op by default so tests
            // need no wiring): a win flushes its queued result immediately.
            syncKickProvider.overrideWith(
              (ref) => () => ref.read(syncEngineProvider).flush(),
            ),
            // Reconcilers get a coins/level refetch: the server mints petals
            // when a puzzle result syncs, so each confirmed result pulls the
            // authoritative profile straight into the cache (pending-delta
            // aware), closing the loop within the session instead of on the
            // next restart.
            mutationReconcilersProvider.overrideWith(
              (ref) => buildMutationReconcilers(
                db,
                onPuzzleResultSynced: () async {
                  final AuthUser? user =
                      ref.read(authRepositoryProvider).currentUser;
                  if (user == null) return;
                  await ref.read(profileRepositoryProvider).fetch(user.uid);
                },
                // A queued forfeit that only reached the server after the
                // player came back online still drops the match from the
                // Resume list, the "Play with friends" badge, and history
                // (issue #38) without a manual pull-to-refresh.
                onMatchLeaveSynced: () async {
                  ref.invalidate(activeMatchesProvider);
                  ref.invalidate(matchHistoryProvider);
                },
              ),
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

class _BootstrapGateState extends ConsumerState<_BootstrapGate>
    with WidgetsBindingObserver {
  SyncScheduler? _scheduler;
  Timer? _flushHeartbeat;

  /// How often the foreground safety net checks for stuck queue rows. Cheap:
  /// each tick is one local DB read; the network is only touched when rows are
  /// actually due, and the engine's single-flight guard absorbs overlaps.
  static const Duration _heartbeatEvery = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (kBackendSyncEnabled) {
      final SyncEngine engine = ref.read(syncEngineProvider);
      _scheduler = createSyncScheduler(
        engine.flush,
        enableBackground: kBackgroundFlushEnabled,
        backgroundEntryPoint: backgroundFlushEntryPoint,
      );
      unawaited(_scheduler!.initialize());
      // Foreground heartbeat: syncs must not depend on a restart or a
      // connectivity flap. Anything sitting in the queue past its backoff gate
      // gets another delivery attempt while the app is simply open.
      _flushHeartbeat = Timer.periodic(_heartbeatEvery, (_) async {
        final due = await ref
            .read(appDatabaseProvider)
            .pendingMutationsDao
            .due(DateTime.now().millisecondsSinceEpoch);
        if (due.isNotEmpty) {
          unawaited(_scheduler?.requestFlush() ?? Future<void>.value());
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Coming back to the app: push anything queued, then pull the server's
    // view of coins/level (pending-delta aware) so both sides converge without
    // the player ever having to restart.
    unawaited(_scheduler?.requestFlush() ?? Future<void>.value());
    final AuthUser? user = ref.read(authRepositoryProvider).currentUser;
    if (user != null) {
      unawaited(
        ref
            .read(profileRepositoryProvider)
            .fetch(user.uid)
            .catchError((Object e) {
          logger.info('resume profile refetch skipped: $e');
          return null;
        }),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flushHeartbeat?.cancel();
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
          // Stop this device receiving the signed-out user's pushes.
          unawaited(ref.read(pushServiceProvider).unregister());
        }
      } else if (uid != prevUid) {
        unawaited(
          ref
              .read(profileControllerProvider.notifier)
              .load(uid, firebaseDisplayName: next.asData?.value?.displayName),
        );
        // Register the FCM token IF permission was already granted. Never prompts
        // here (prompt: false) so a restored session shows no dialog at launch;
        // the Friends page owns the first, deliberate permission request.
        unawaited(
          ref.read(pushServiceProvider).registerForUser(uid, prompt: false),
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
