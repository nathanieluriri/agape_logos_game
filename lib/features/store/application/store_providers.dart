import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/offline/offline_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../../profile/application/profile_providers.dart';
import '../../puzzles/puzzles_config.dart';
import '../data/store_remote.dart';
import '../data/store_repository_impl.dart';
import '../domain/purchase_outcome.dart';
import '../domain/store_item.dart';
import '../domain/store_repository.dart';

final storeRemoteProvider = Provider<StoreRemote>(
  (ref) => HttpStoreRemote(ref.watch(apiClientProvider)),
);

final storeRepositoryProvider = Provider<StoreRepository>(
  (ref) => StoreRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(storeRemoteProvider),
  ),
);

/// The catalog (`GET /store`). Read once when the store opens; refetch by
/// invalidating this provider.
final storeCatalogProvider = FutureProvider<List<StoreItem>>(
  (ref) => ref.watch(storeRepositoryProvider).catalog(),
);

/// Fired once when the store opens (the body watches it): deliver any queued
/// winnings, then pull the fresh balance (pending-delta aware). This closes
/// the "won petals, walked straight into the store" gap: by the time the
/// player taps Buy, the server has usually already minted what they see.
/// Best-effort: offline just leaves the cached balance in place.
final storeEntrySyncProvider = FutureProvider.autoDispose<void>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return;
  try {
    await ref.read(syncKickProvider)();
    await ref.read(profileRepositoryProvider).fetchCoins(user.uid);
  } catch (e) {
    logger.info('store entry sync skipped: $e');
  }
});

/// The caller's owned consumables (`GET /me/inventory`). Held in a notifier so a
/// purchase can push the server's authoritative post-buy inventory in without a
/// refetch.
class InventoryController extends AsyncNotifier<Map<String, int>> {
  @override
  Future<Map<String, int>> build() =>
      ref.watch(storeRepositoryProvider).inventory();

  /// Replace the cached inventory with the server's post-purchase snapshot.
  void applyServer(Map<String, int> inventory) {
    state = AsyncData<Map<String, int>>(inventory);
  }

  Future<void> refresh() async {
    state = const AsyncLoading<Map<String, int>>();
    state = await AsyncValue.guard(
      () => ref.read(storeRepositoryProvider).inventory(),
    );
  }
}

final inventoryControllerProvider =
    AsyncNotifierProvider<InventoryController, Map<String, int>>(
      InventoryController.new,
    );

/// Tracks which item ids have an in-flight purchase, so each card can disable
/// just its own buy button while its request is out.
class StorePurchaseController extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  bool isBuying(String itemId) => state.contains(itemId);

  /// Buys [item]. Returns the outcome for the caller to surface (a snack). When
  /// signed out, returns [PurchaseUnavailable] without a network call.
  ///
  /// Sync-aware: winnings can still be travelling in the offline queue while
  /// the server (which the purchase is checked against) hasn't minted them
  /// yet. So the flow is: flush pending winnings first, buy, and on an
  /// insufficient-coins answer either retry once (the flush just landed) or,
  /// when the queue still holds undelivered results, report
  /// [PurchaseCoinsSyncing] instead of a misleading "not enough".
  Future<PurchaseOutcome> buy(StoreItem item, {int quantity = 1}) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return const PurchaseUnavailable();

    state = <String>{...state, item.id};
    try {
      // 1) Deliver any pending winnings before the server checks the wallet.
      if (await _hasPendingWinnings()) {
        await ref.read(syncKickProvider)();
      }

      var outcome = await _attempt(user.uid, item, quantity);

      if (outcome is PurchaseInsufficientCoins) {
        if (await _hasPendingWinnings()) {
          // The flush could not drain the queue (offline / backing off): the
          // server genuinely hasn't seen the petals on screen yet.
          return PurchaseCoinsSyncing(
            cost: outcome.cost,
            coins: outcome.coins,
          );
        }
        // Queue is empty now: the winnings may have landed BETWEEN the 402
        // and this check (e.g. a background flush won the race). One retry.
        if (ref.read(coinsProvider) >= outcome.cost) {
          outcome = await _attempt(user.uid, item, quantity);
        }
      }
      return outcome;
    } finally {
      state = <String>{...state}..remove(item.id);
    }
  }

  Future<PurchaseOutcome> _attempt(
    String uid,
    StoreItem item,
    int quantity,
  ) async {
    final outcome = await ref
        .read(storeRepositoryProvider)
        .purchase(uid: uid, itemId: item.id, quantity: quantity);
    if (outcome is PurchaseSuccess) {
      ref
          .read(inventoryControllerProvider.notifier)
          .applyServer(outcome.inventory);
    }
    return outcome;
  }

  Future<bool> _hasPendingWinnings() async {
    try {
      final rows = await ref
          .read(appDatabaseProvider)
          .pendingMutationsDao
          .unsynced(const [kPuzzleResultKind]);
      return rows.isNotEmpty;
    } catch (e) {
      // No queue available (tests/previews without storage wiring): treat as
      // nothing pending so the purchase proceeds on the server's answer alone.
      logger.info('pending-winnings check skipped: $e');
      return false;
    }
  }
}

final storePurchaseControllerProvider =
    NotifierProvider<StorePurchaseController, Set<String>>(
      StorePurchaseController.new,
    );
