import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:agape_logos_game/features/profile/data/profile_mappers.dart';
import 'package:agape_logos_game/features/profile/domain/profile.dart';
import 'package:agape_logos_game/features/store/data/store_remote.dart';
import 'package:agape_logos_game/features/store/data/store_repository_impl.dart';
import 'package:agape_logos_game/features/store/domain/purchase_outcome.dart';
import 'package:agape_logos_game/features/store/domain/store_item.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Profile _profile(String uid, {int coins = 0}) => Profile(
      uid: uid,
      displayName: 'Player',
      avatarId: 'avatar_01',
      locale: 'en',
      soundEnabled: true,
      musicEnabled: true,
      highestLevel: 6,
      totalScore: 0,
      coins: coins,
      createdAt: 1000,
      updatedAt: 2000,
    );

class _FakeRemote implements StoreRemote {
  _FakeRemote(this.outcome);
  PurchaseOutcome outcome;
  int purchaseCalls = 0;
  String? lastItemId;
  int? lastQuantity;

  @override
  Future<List<StoreItem>> catalog() async => const <StoreItem>[];

  @override
  Future<Map<String, int>> inventory() async => const <String, int>{};

  @override
  Future<PurchaseOutcome> purchase({
    required String idempotencyKey,
    required String itemId,
    required int quantity,
  }) async {
    purchaseCalls++;
    lastItemId = itemId;
    lastQuantity = quantity;
    return outcome;
  }
}

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> seed(String uid, int coins) =>
      db.cachedProfileDao.upsert(profileToCompanion(_profile(uid, coins: coins)));

  test('a successful purchase writes the returned balance through to the cache',
      () async {
    await seed('u1', 500);
    final remote = _FakeRemote(
      const PurchaseSuccess(
        coins: 450,
        inventory: <String, int>{'hint': 1},
        charged: 50,
        replay: false,
      ),
    );
    final repo = StoreRepositoryImpl(db, remote);

    final outcome = await repo.purchase(uid: 'u1', itemId: 'hint');

    expect(outcome, isA<PurchaseSuccess>());
    expect(remote.purchaseCalls, 1);
    expect(remote.lastItemId, 'hint');
    expect(remote.lastQuantity, 1);
    final cached = await db.cachedProfileDao.read('u1');
    expect(cached?.coins, 450); // server truth written through
  });

  test('insufficient coins leaves the cached balance untouched', () async {
    await seed('u1', 30);
    final repo = StoreRepositoryImpl(
      db,
      _FakeRemote(const PurchaseInsufficientCoins(cost: 50, coins: 30)),
    );

    final outcome = await repo.purchase(uid: 'u1', itemId: 'hint');

    expect(outcome, isA<PurchaseInsufficientCoins>());
    final cached = await db.cachedProfileDao.read('u1');
    expect(cached?.coins, 30); // unchanged
  });

  test('an unavailable purchase does not touch the cache', () async {
    await seed('u1', 100);
    final repo = StoreRepositoryImpl(
      db,
      _FakeRemote(const PurchaseUnavailable()),
    );

    final outcome = await repo.purchase(uid: 'u1', itemId: 'hint');

    expect(outcome, isA<PurchaseUnavailable>());
    final cached = await db.cachedProfileDao.read('u1');
    expect(cached?.coins, 100);
  });
}
