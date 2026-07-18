import 'package:agape_logos_game/features/auth/application/auth_providers.dart';
import 'package:agape_logos_game/features/auth/domain/auth_user.dart';
import 'package:agape_logos_game/features/profile/application/profile_providers.dart';
import 'package:agape_logos_game/features/store/application/store_providers.dart';
import 'package:agape_logos_game/features/store/domain/purchase_outcome.dart';
import 'package:agape_logos_game/features/store/domain/store_item.dart';
import 'package:agape_logos_game/features/store/domain/store_repository.dart';
import 'package:agape_logos_game/features/store/presentation/pages/store_page.dart';
import 'package:agape_logos_game/game/ambient/ambient_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _hint = StoreItem(
  id: 'hint',
  name: 'Hint',
  description: 'Reveal a letter.',
  category: 'hint',
  kind: 'hint',
  cost: 50,
  maxPerPurchase: 20,
);

class _FakeStoreRepo implements StoreRepository {
  _FakeStoreRepo({required this.outcome, this.items = const <StoreItem>[]});
  final PurchaseOutcome outcome;
  final List<StoreItem> items;
  int purchaseCalls = 0;
  int catalogCalls = 0;
  int inventoryCalls = 0;

  @override
  Future<List<StoreItem>> catalog() async {
    catalogCalls++;
    return items;
  }

  @override
  Future<Map<String, int>> inventory() async {
    inventoryCalls++;
    return const <String, int>{};
  }

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

Future<void> _pumpStore(
  WidgetTester tester, {
  required PurchaseOutcome outcome,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ambientEnabledProvider.overrideWithValue(false),
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'u1')),
        coinsProvider.overrideWithValue(500),
        storeRepositoryProvider.overrideWithValue(
          _FakeStoreRepo(outcome: outcome, items: const <StoreItem>[_hint]),
        ),
      ],
      child: const MaterialApp(home: StorePage()),
    ),
  );
  // Resolve the catalog + inventory futures.
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('renders a catalog item with a Buy action', (tester) async {
    await _pumpStore(
      tester,
      outcome: const PurchaseSuccess(
        coins: 450,
        inventory: <String, int>{'hint': 1},
        charged: 50,
        replay: false,
      ),
    );

    expect(find.text('Reveal a letter.'), findsOneWidget);
    expect(find.bySemanticsLabel('Buy Hint for 50 petals'), findsOneWidget);
  });

  testWidgets('buying an item shows a success snack', (tester) async {
    await _pumpStore(
      tester,
      outcome: const PurchaseSuccess(
        coins: 450,
        inventory: <String, int>{'hint': 1},
        charged: 50,
        replay: false,
      ),
    );

    await tester.tap(find.bySemanticsLabel('Buy Hint for 50 petals'));
    await tester.pump(); // enter busy state
    await tester.pump(); // purchase resolves
    await tester.pump(); // snack shows

    expect(find.text('Hint purchased!'), findsOneWidget);
  });

  testWidgets('an unaffordable item explains the shortfall', (tester) async {
    await _pumpStore(
      tester,
      outcome: const PurchaseInsufficientCoins(cost: 50, coins: 10),
    );

    await tester.tap(find.bySemanticsLabel('Buy Hint for 50 petals'));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Not enough petals. Hint costs 50, you have 10.'),
      findsOneWidget,
    );
  });

  testWidgets('pull-to-refresh refetches the catalog and the inventory', (
    tester,
  ) async {
    final repo = _FakeStoreRepo(
      outcome: const PurchaseUnavailable(),
      items: const <StoreItem>[_hint],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ambientEnabledProvider.overrideWithValue(false),
          currentUserProvider.overrideWithValue(const AuthUser(uid: 'u1')),
          coinsProvider.overrideWithValue(500),
          storeRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(home: StorePage()),
      ),
    );
    // Resolve the catalog + inventory futures.
    await tester.pump();
    await tester.pump();

    expect(repo.catalogCalls, 1);
    expect(repo.inventoryCalls, 1);

    // Invoke the wired onRefresh callback directly rather than driving a
    // drag gesture or RefreshIndicatorState.show(): both hinge on the
    // indicator's AnimationController ticking forward, and this page's
    // loading state renders an indeterminate PondLoader that "loops forever
    // by design" (see pond_loader_test.dart), so a real gesture or
    // pumpAndSettle can hang. Calling the callback exercises exactly what a
    // pull gesture would trigger, deterministically.
    final RefreshIndicator indicator = tester.widget<RefreshIndicator>(
      find.byType(RefreshIndicator),
    );
    await indicator.onRefresh();
    await tester.pump();
    await tester.pump();

    expect(repo.catalogCalls, 2);
    expect(repo.inventoryCalls, 2);
  });
}
