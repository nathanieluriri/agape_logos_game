import 'package:agape_logos_game/core/haptics/haptic_providers.dart';
import 'package:agape_logos_game/core/haptics/haptic_service.dart';
import 'package:agape_logos_game/features/auth/application/auth_providers.dart';
import 'package:agape_logos_game/features/store/domain/store_item.dart';
import 'package:agape_logos_game/features/store/presentation/widgets/store_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records which service methods fire, so the test can assert the wiring without
/// any real vibration.
class _RecordingHaptics implements HapticService {
  final List<String> calls = <String>[];
  @override
  Future<void> init() async {}
  @override
  Future<void> lightImpact() async => calls.add('light');
  @override
  Future<void> mediumImpact() async => calls.add('medium');
  @override
  Future<void> heavyImpact() async => calls.add('heavy');
  @override
  Future<void> gameImpact() async => calls.add('game');
  @override
  Future<void> streakImpact() async => calls.add('streak');
  @override
  Future<void> mistakeImpact() async => calls.add('mistake');
  @override
  Future<void> selectionClick() async => calls.add('selection');
  @override
  Future<void> successPattern() async => calls.add('success');
  @override
  Future<void> tickImpact() async => calls.add('tick');
  @override
  void setMuted(bool muted) {}
}

const _item = StoreItem(
  id: 'hint',
  name: 'Hint',
  description: 'Reveal a letter',
  category: 'hint',
  kind: 'hint',
  cost: 50,
  maxPerPurchase: 5,
);

void main() {
  testWidgets('a failed (signed-out) purchase fires the mistake haptic',
      (tester) async {
    final haptics = _RecordingHaptics();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hapticServiceProvider.overrideWithValue(haptics),
          // Signed out: StorePurchaseController.buy returns PurchaseUnavailable
          // with no network, so the card takes its failure branch deterministically.
          currentUserProvider.overrideWithValue(null),
        ],
        child: const MaterialApp(
          home: Scaffold(body: StoreItemCard(item: _item, owned: 0)),
        ),
      ),
    );

    await tester.tap(find.text('Buy'));
    await tester.pump(); // resolve _buy's async future
    await tester.pump();

    expect(haptics.calls, contains('mistake'));
  });
}
