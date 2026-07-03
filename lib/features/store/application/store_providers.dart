import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../../auth/application/auth_providers.dart';
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
  Future<PurchaseOutcome> buy(StoreItem item, {int quantity = 1}) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return const PurchaseUnavailable();

    state = <String>{...state, item.id};
    try {
      final outcome = await ref.read(storeRepositoryProvider).purchase(
            uid: user.uid,
            itemId: item.id,
            quantity: quantity,
          );
      if (outcome is PurchaseSuccess) {
        ref.read(inventoryControllerProvider.notifier).applyServer(
              outcome.inventory,
            );
      }
      return outcome;
    } finally {
      state = <String>{...state}..remove(item.id);
    }
  }
}

final storePurchaseControllerProvider =
    NotifierProvider<StorePurchaseController, Set<String>>(
  StorePurchaseController.new,
);
