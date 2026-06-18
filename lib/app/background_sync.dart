import 'dart:ui' show DartPluginRegistrant;

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../core/connectivity/connectivity_service.dart';
import '../core/network/api_client.dart';
import '../core/network/sync_dio.dart';
import '../core/offline/http_mutation_sender.dart';
import '../core/offline/sync_engine.dart';
import '../core/offline/sync_scheduler_android.dart' show kFlushTask;
import '../core/storage/app_database.dart';
import '../features/auth/data/firebase_auth_repository.dart';
import '../features/auth/domain/auth_user.dart';
import '../firebase_options.dart';
import 'sync_reconcilers.dart';

/// WorkManager background entry point. Runs in a FRESH isolate with no Riverpod
/// scope, so it constructs its own dependencies and uses the shared, Riverpod-free
/// builders. Top-level + `@pragma('vm:entry-point')` so the engine can resolve its
/// callback handle.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Bootstrap plugins in this isolate. DartPluginRegistrant is REQUIRED:
    // workmanager 0.9.0+3 does not register federated plugins for the background
    // isolate, so without it Firebase/Drift/connectivity throw
    // MissingPluginException. WidgetsFlutterBinding is idempotent/defensive.
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    if (task != kFlushTask) return true;

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // Auth guard AFTER hydration: a fresh isolate has currentUser == null until
    // Firebase restores the persisted user asynchronously. Await the first
    // restored state; signed out OR timeout -> skip, burning no retries.
    final FirebaseAuthRepository auth = FirebaseAuthRepository();
    final AuthUser? user = await auth.awaitRestoredUser();
    if (user == null) return true;

    // Build db + dio before the try so the finally can close both (no provider
    // onDispose in the isolate).
    final AppDatabase db = AppDatabase();
    final Dio dio = buildSyncDio(
      connectivity: ConnectivityService(),
      idToken: auth.idToken,
    );
    try {
      final ApiClient api = ApiClient(dio);
      final HttpMutationSender sender =
          HttpMutationSender(api: api, auth: auth);
      final SyncEngine engine = SyncEngine(
        db: db,
        connectivity: ConnectivityService(),
        sender: sender.send,
        reconcilers: buildMutationReconcilers(db),
      );
      await engine.flush();
    } finally {
      dio.close(force: true);
      await db.close();
    }
    return true;
  });
}
