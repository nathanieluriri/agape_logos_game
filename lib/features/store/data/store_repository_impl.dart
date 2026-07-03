import 'package:uuid/uuid.dart';

import '../../../core/storage/app_database.dart';
import '../domain/purchase_outcome.dart';
import '../domain/store_item.dart';
import '../domain/store_repository.dart';
import 'store_remote.dart';

/// [StoreRepository] over the HTTP remote. On a successful purchase it writes the
/// server's authoritative coin balance through to the cached profile (the single
/// source of truth the wallet pill reads), so the balance updates without an
/// extra `GET /me`. Inventory is returned to the caller for the store UI to hold.
class StoreRepositoryImpl implements StoreRepository {
  StoreRepositoryImpl(this._db, this._remote, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final StoreRemote _remote;
  final Uuid _uuid;

  @override
  Future<List<StoreItem>> catalog() => _remote.catalog();

  @override
  Future<Map<String, int>> inventory() => _remote.inventory();

  @override
  Future<PurchaseOutcome> purchase({
    required String uid,
    required String itemId,
    int quantity = 1,
  }) async {
    // A fresh idempotency key per attempt: the server dedupes replays of the
    // same key, so a client-side retry of the exact same call is safe. We do not
    // reuse a key across distinct user taps (each tap is a new intended charge).
    final outcome = await _remote.purchase(
      idempotencyKey: _uuid.v4(),
      itemId: itemId,
      quantity: quantity,
    );
    if (outcome is PurchaseSuccess) {
      await _db.cachedProfileDao.setCoins(uid, outcome.coins);
    }
    return outcome;
  }
}
