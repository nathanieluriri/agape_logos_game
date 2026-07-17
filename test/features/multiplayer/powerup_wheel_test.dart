import 'package:agape_logos_game/features/multiplayer/presentation/widgets/powerup_wheel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ownedCounts = {'freeze_letter': 3, 'fog': 0, 'scramble': 0, 'word_steal': 0};
  const prices = {'freeze_letter': 120, 'fog': 100, 'scramble': 90, 'word_steal': 260};

  Widget harness({
    required void Function(String kind, Offset release) onFire,
    required void Function(String itemId) onTapInfo,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: PowerupWheel(
          category: PowerupCategory.offense,
          ownedCounts: ownedCounts,
          prices: prices,
          onFire: onFire,
          onTapInfo: onTapInfo,
          onClose: () {},
        ),
      ),
    );
  }

  testWidgets('renders 4 offense slots with counts and prices', (tester) async {
    await tester.pumpWidget(harness(onFire: (_, __) {}, onTapInfo: (_) {}));
    await tester.pumpAndSettle();

    expect(find.text('x3'), findsOneWidget);
    expect(find.text('100'), findsOneWidget);
    expect(find.text('90'), findsOneWidget);
    expect(find.text('260'), findsOneWidget);
  });

  testWidgets('dragging an owned slot out and releasing fires it', (tester) async {
    String? firedKind;
    await tester.pumpWidget(
      harness(onFire: (kind, __) => firedKind = kind, onTapInfo: (_) {}),
    );
    await tester.pumpAndSettle();

    final slot = find.byKey(const ValueKey('powerup_slot_freeze_letter'));
    expect(slot, findsOneWidget);
    await tester.drag(slot, const Offset(0, -150));
    await tester.pumpAndSettle();

    expect(firedKind, 'letter_freeze');
  });

  testWidgets('dragging an unowned slot does nothing but a tap opens info', (
    tester,
  ) async {
    String? firedKind;
    String? infoItemId;
    await tester.pumpWidget(
      harness(
        onFire: (kind, __) => firedKind = kind,
        onTapInfo: (itemId) => infoItemId = itemId,
      ),
    );
    await tester.pumpAndSettle();

    final slot = find.byKey(const ValueKey('powerup_slot_fog'));
    await tester.drag(slot, const Offset(0, -150));
    await tester.pumpAndSettle();
    expect(firedKind, isNull);

    await tester.tap(slot);
    await tester.pumpAndSettle();
    expect(infoItemId, 'fog');
  });
}
