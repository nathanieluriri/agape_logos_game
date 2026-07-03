import 'purchase_outcome.dart';
import 'store_item.dart';

/// Boundary for the coin store. All three calls are `OnlineOnly` in the
/// `core/offline/call_policy.dart` sense: the catalog and inventory are pure
/// reads, and a purchase is a server-authoritative write (the wallet lives on
/// the server). A successful purchase writes the returned coin balance through
/// to the cached profile so the wallet pill updates without a separate refetch.
abstract interface class StoreRepository {
  /// The full catalog (`GET /store`): base consumables, powerups, and bundles.
  Future<List<StoreItem>> catalog();

  /// The caller's owned consumables (`GET /me/inventory`), keyed by base item id.
  Future<Map<String, int>> inventory();

  /// Spends coins on [quantity] of [itemId] (`POST /store/purchase`). Carries an
  /// idempotency key so a network retry cannot double-charge.
  Future<PurchaseOutcome> purchase({
    required String uid,
    required String itemId,
    int quantity = 1,
  });
}
