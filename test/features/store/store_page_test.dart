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

  @override
  Future<List<StoreItem>> catalog() async => items;

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
    expect(find.bySemanticsLabel('Buy Hint for 50 coins'), findsOneWidget);
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

    await tester.tap(find.bySemanticsLabel('Buy Hint for 50 coins'));
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

    await tester.tap(find.bySemanticsLabel('Buy Hint for 50 coins'));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Not enough coins. Hint costs 50, you have 10.'),
      findsOneWidget,
    );
  });
}
