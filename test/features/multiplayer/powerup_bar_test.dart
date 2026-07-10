import 'package:agape_logos_game/features/multiplayer/application/match_providers.dart';
import 'package:agape_logos_game/features/multiplayer/data/match_remote.dart';
import 'package:agape_logos_game/features/multiplayer/presentation/widgets/powerup_bar.dart';
import 'package:agape_logos_game/features/store/application/store_providers.dart';
import 'package:agape_logos_game/features/store/domain/store_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRemote implements MatchRemote {
  String? firedRule;
  @override
  Future<bool> powerup(String matchId, String kind, {required String eventId}) async {
    firedRule = kind;
    return true;
  }
  @override
  Future<({String matchId, String code})> create(Map<String, dynamic> s) async =>
      (matchId: 'm1', code: 'ABCD');
  @override
  Future<String> join(String code) async => 'm1';
  @override
  Future<void> ready(String matchId, {required bool ready}) async {}
  @override
  Future<void> start(String matchId) async {}
  @override
  Future<void> submit(String matchId, String word) async {}
  @override
  Future<void> leave(String matchId) async {}
}

class _FakeInventory extends InventoryController {
  @override
  Future<Map<String, int>> build() async => {'pw_fog': 2};
}

StoreItem _fog() => const StoreItem(
      id: 'pw_fog', name: 'Fog Bank', description: '', category: 'powerup',
      kind: 'offense', cost: 50, maxPerPurchase: 5,
      effect: PowerupEffect(target: 'opponent', durationSec: 8, rule: 'fog_bank'),
    );

void main() {
  testWidgets('firing an owned powerup calls the remote with its rule',
      (tester) async {
    final fake = _FakeRemote();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        matchServiceProvider.overrideWithValue(fake),
        storeCatalogProvider.overrideWith((ref) async => [_fog()]),
        inventoryControllerProvider.overrideWith(_FakeInventory.new),
      ],
      child: const MaterialApp(home: Scaffold(body: PowerupBar(matchId: 'm1'))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('x2'), findsOneWidget);
    await tester.tap(find.byType(GestureDetector).first);
    await tester.pump();
    expect(fake.firedRule, 'fog_bank');
  });
}
