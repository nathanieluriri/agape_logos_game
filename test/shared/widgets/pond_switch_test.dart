// test/shared/widgets/pond_switch_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agape_logos_game/shared/widgets/pond_switch.dart';

void main() {
  testWidgets('PondSwitch fires onChanged with the toggled value',
      (tester) async {
    bool? received;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: PondSwitch(
            value: false,
            semanticLabel: 'Sound effects',
            onChanged: (value) => received = value,
          ),
        ),
      ),
    ));
    await tester.tap(find.byType(PondSwitch));
    await tester.pump(const Duration(milliseconds: 300));
    expect(received, isTrue);
  });

  testWidgets('PondSwitch exposes toggled button semantics', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: PondSwitch(
            value: true,
            semanticLabel: 'Music',
            onChanged: (_) {},
          ),
        ),
      ),
    ));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Music')),
      isSemantics(label: 'Music', isToggled: true, isButton: true),
    );
  });
}
