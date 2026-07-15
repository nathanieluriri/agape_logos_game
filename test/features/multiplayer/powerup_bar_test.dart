import 'package:agape_logos_game/features/multiplayer/application/match_providers.dart';
import 'package:agape_logos_game/features/multiplayer/data/match_remote.dart';
import 'package:agape_logos_game/features/multiplayer/domain/active_match.dart';
import 'package:agape_logos_game/features/multiplayer/domain/challenge_outcome.dart';
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

  @override
  Future<void> settle(String matchId) async {}

  @override
  Future<ChallengeOutcome> challenge(String toUid, {required String mode}) async =>
      const ChallengeSent('m1');

  @override
  Future<void> respondChallenge(String matchId, {required bool accept}) async {}

  @override
  Future<List<ActiveMatch>> activeMatches() async => const [];
}

class _FakeInventory extends InventoryController {
  @override
  Future<Map<String, int>> build() async => {'fog': 2, 'shield': 1};
}

/// The REAL catalog shape (functions/src/store/catalog.ts): the id is `fog`, and
/// `effect.rule` is human rules text, NOT the wire kind. The old fixture here
/// used id `pw_fog` with rule `fog_bank`, which is why this test stayed green
/// while every powerup in production was rejected with a 400.
StoreItem _fog() => const StoreItem(
      id: 'fog',
      name: 'Fog Bank',
      description: "Blur your opponent's board for 8 seconds.",
      category: 'powerup',
      kind: 'offense',
      cost: 100,
      maxPerPurchase: 10,
      effect: PowerupEffect(
        target: 'opponent',
        durationSec: 8,
        rule: "Obscure the opponent's board for 8s.",
      ),
    );

/// Defense: now server-implemented (armed shield in activeEffects), so it IS
/// firable from the bar.
StoreItem _shield() => const StoreItem(
      id: 'shield',
      name: 'Bubble Shield',
      description: 'Nullify the next powerup used against you.',
      category: 'powerup',
      kind: 'defense',
      cost: 150,
      maxPerPurchase: 10,
      effect: PowerupEffect(
        target: 'self',
        durationSec: 0,
        rule: 'Block the next incoming powerup.',
      ),
    );

void main() {
  testWidgets('firing an owned powerup sends the wire KIND, not the rules text',
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
    // The server validates this against a zod enum. Sending effect.rule (the
    // prose) is a 400 and the powerup silently never fires.
    expect(fake.firedRule, 'fog_bank');
  });

  testWidgets('server-implemented defense powerups are offered in the match bar',
      (tester) async {
    final fake = _FakeRemote();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        matchServiceProvider.overrideWithValue(fake),
        storeCatalogProvider.overrideWith((ref) async => [_fog(), _shield()]),
        inventoryControllerProvider.overrideWith(_FakeInventory.new),
      ],
      child: const MaterialApp(home: Scaffold(body: PowerupBar(matchId: 'm1'))),
    ));
    await tester.pumpAndSettle();

    // Both are firable now: shield arms server-side into activeEffects.
    expect(find.bySemanticsLabel(RegExp('Fog Bank')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Bubble Shield')), findsOneWidget);
  });
}
