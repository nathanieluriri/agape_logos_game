import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_providers.dart';
import '../../../shared/widgets/sync_status_badge.dart';
import '../../level_results/data/level_result_repository_impl.dart';
import '../../puzzles/puzzles_config.dart';

/// How long the green "synced" tick lingers after the server confirms, before
/// the badge settles to nothing (local and server agree; no chrome needed).
const Duration kSyncedTickHold = Duration(milliseconds: 2500);

/// The wallet/progress delivery state, derived live from the offline queue:
///
/// * any result mutation pending/in-flight  -> [SyncBadgeStatus.syncing]
/// * queue just drained after syncing       -> [SyncBadgeStatus.synced]
///   (held for [kSyncedTickHold], then [SyncBadgeStatus.none])
/// * only permanently-failed rows remain    -> [SyncBadgeStatus.failed]
/// * otherwise                              -> [SyncBadgeStatus.none]
///
/// Because it watches the queue table itself, the badge flips to "syncing" the
/// instant a win is enqueued and to "synced" the instant the engine confirms:
/// no polling, no restart.
final _walletSyncStatusStreamProvider = StreamProvider<SyncBadgeStatus>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final controller = StreamController<SyncBadgeStatus>();
  Timer? settle;
  var sawSyncing = false;
  var current = SyncBadgeStatus.none;

  void emit(SyncBadgeStatus next) {
    if (next == current || controller.isClosed) return;
    current = next;
    controller.add(next);
  }

  final sub = db.pendingMutationsDao
      .watchOutstanding(const [kPuzzleResultKind, kLevelResultKind])
      .listen((rows) {
    final hasPending = rows.any(
      (r) => r.status == 'pending' || r.status == 'inFlight',
    );
    final hasFailed = rows.any((r) => r.status == 'failed');
    if (hasPending) {
      sawSyncing = true;
      settle?.cancel();
      emit(SyncBadgeStatus.syncing);
    } else if (hasFailed) {
      settle?.cancel();
      emit(SyncBadgeStatus.failed);
    } else if (sawSyncing) {
      // The queue just drained: show the confirmation tick briefly, then rest.
      sawSyncing = false;
      emit(SyncBadgeStatus.synced);
      settle?.cancel();
      settle = Timer(kSyncedTickHold, () => emit(SyncBadgeStatus.none));
    } else {
      emit(SyncBadgeStatus.none);
    }
  });

  ref.onDispose(() {
    sub.cancel();
    settle?.cancel();
    controller.close();
  });
  return controller.stream;
});

/// Plain synchronous view for widgets: the current badge state, [SyncBadgeStatus.none]
/// before the first queue emission.
final walletSyncBadgeProvider = Provider<SyncBadgeStatus>(
  (ref) =>
      ref.watch(_walletSyncStatusStreamProvider).value ?? SyncBadgeStatus.none,
);
