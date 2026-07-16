import 'package:agape_logos_game/core/offline/offline_providers.dart';
import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:agape_logos_game/core/storage/storage_providers.dart';
import 'package:agape_logos_game/features/auth/application/auth_providers.dart';
import 'package:agape_logos_game/features/auth/domain/auth_user.dart';
import 'package:agape_logos_game/features/profile/application/profile_providers.dart';
import 'package:agape_logos_game/features/profile/data/profile_mappers.dart';
import 'package:agape_logos_game/features/profile/domain/profile.dart';
import 'package:agape_logos_game/features/puzzles/puzzles_config.dart';
import 'package:agape_logos_game/features/store/application/store_providers.dart';
import 'package:agape_logos_game/features/store/data/store_remote.dart';
import 'package:agape_logos_game/features/store/data/store_repository_impl.dart';
import 'package:agape_logos_game/features/store/domain/purchase_outcome.dart';
import 'package:agape_logos_game/features/store/domain/store_item.dart';
import 'package:agape_logos_game/features/store/domain/store_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _item = StoreItem(
  id: 'hint',
  name: 'Hint',
  description: 'Reveal a letter.',
  category: 'hint',
  kind: 'hint',
  cost: 200,
  maxPerPurchase: 20,
);

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

/// Repository fake for the controller flow tests: returns a fixed outcome and
/// counts attempts.
class _FakeRepo implements StoreRepository {
  _FakeRepo(this.outcome);
  final PurchaseOutcome outcome;
  int purchaseCalls = 0;

  @override
  Future<List<StoreItem>> catalog() async => const <StoreItem>[];

  @override
  Future<Map<String, int>> inventory() async => const <String, int>{};

  @override
  Future<PurchaseOutcome> purchase({
    required String uid,
    required String itemId,
    int quantity = 1,
  }) async {
    purchaseCalls++;
    return outcome;
  }
}

/// Remote fake for the write-through test (drives the REAL repository).
class _FakeRemote implements StoreRemote {
  _FakeRemote(this.outcome);
  final PurchaseOutcome outcome;

  @override
  Future<List<StoreItem>> catalog() async => const <StoreItem>[];

  @override
  Future<Map<String, int>> inventory() async => const <String, int>{};

  @override
  Future<PurchaseOutcome> purchase({
    required String idempotencyKey,
    required String itemId,
    required int quantity,
  }) async =>
      outcome;
}

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> enqueueResult(String id, {int score = 58}) {
    return db.pendingMutationsDao.enqueue(
      PendingMutationsCompanion.insert(
        id: id,
        endpoint: '/puzzles/$id/result',
        method: 'POST',
        payloadJson: '{"score":$score}',
        idempotencyKey: id,
        kind: kPuzzleResultKind,
        createdAt: 1,
      ),
    );
  }

  ProviderContainer container({
    required StoreRepository repo,
    required Future<void> Function() kick,
    int coins = 0,
  }) {
    final c = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'u1')),
        appDatabaseProvider.overrideWithValue(db),
        storeRepositoryProvider.overrideWithValue(repo),
        syncKickProvider.overrideWithValue(kick),
        coinsProvider.overrideWithValue(coins),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('402 while the queue is still non-empty returns PurchaseCoinsSyncing',
      () async {
    await enqueueResult('p1'); // winnings the server has not seen
    final repo = _FakeRepo(const PurchaseInsufficientCoins(cost: 200, coins: 165));
    var kicks = 0;
    final c = container(
      repo: repo,
      // The flush cannot drain the queue (offline / backing off).
      kick: () async => kicks++,
      coins: 233,
    );

    final outcome =
        await c.read(storePurchaseControllerProvider.notifier).buy(_item);

    expect(outcome, isA<PurchaseCoinsSyncing>());
    final syncing = outcome as PurchaseCoinsSyncing;
    expect(syncing.cost, 200);
    expect(syncing.coins, 165);
    expect(kicks, greaterThanOrEqualTo(1)); // flushed before buying
    expect(repo.purchaseCalls, 1); // and did NOT blind-retry
  });

  test('402 with a drained queue and sufficient local coins retries once',
      () async {
    final repo = _FakeRepo(const PurchaseInsufficientCoins(cost: 200, coins: 165));
    final c = container(repo: repo, kick: () async {}, coins: 233);

    final outcome =
        await c.read(storePurchaseControllerProvider.notifier).buy(_item);

    // Second attempt also 402s, so the honest outcome surfaces, after
    // exactly one retry (no loop).
    expect(outcome, isA<PurchaseInsufficientCoins>());
    expect(repo.purchaseCalls, 2);
  });

  test('402 with a drained queue and genuinely short local coins: no retry',
      () async {
    final repo = _FakeRepo(const PurchaseInsufficientCoins(cost: 200, coins: 165));
    final c = container(repo: repo, kick: () async {}, coins: 165);

    final outcome =
        await c.read(storePurchaseControllerProvider.notifier).buy(_item);

    expect(outcome, isA<PurchaseInsufficientCoins>());
    expect(repo.purchaseCalls, 1);
  });

  test('a successful purchase writes server coins + pendingCoinDelta through',
      () async {
    await db.cachedProfileDao
        .upsert(profileToCompanion(_profile('u1', coins: 700)));
    await enqueueResult('p1', score: 58); // delta = 10 + 58 = 68
    final repo = StoreRepositoryImpl(
      db,
      _FakeRemote(
        const PurchaseSuccess(
          coins: 450, // server view: excludes the queued 68
          inventory: <String, int>{'hint': 1},
          charged: 200,
          replay: false,
        ),
      ),
    );

    final outcome = await repo.purchase(uid: 'u1', itemId: 'hint');

    expect(outcome, isA<PurchaseSuccess>());
    expect((await db.cachedProfileDao.read('u1'))?.coins, 450 + 68);
  });

  test('an insufficient-coins response also reconciles the cached balance',
      () async {
    await db.cachedProfileDao
        .upsert(profileToCompanion(_profile('u1', coins: 999)));
    await enqueueResult('p1', score: 58); // delta = 68
    final repo = StoreRepositoryImpl(
      db,
      _FakeRemote(const PurchaseInsufficientCoins(cost: 200, coins: 165)),
    );

    await repo.purchase(uid: 'u1', itemId: 'hint');

    // Drifted 999 self-heals to server + delta.
    expect((await db.cachedProfileDao.read('u1'))?.coins, 165 + 68);
  });
}
