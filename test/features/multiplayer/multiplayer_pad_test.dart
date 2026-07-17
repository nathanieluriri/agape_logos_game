import 'package:agape_logos_game/features/multiplayer/presentation/widgets/multiplayer_pad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('multiplayer pad renders the Versus affordance', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: Scaffold(body: Center(child: MultiplayerPad()))),
    ));
    await tester.pump();
    expect(find.text('Versus'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Versus, play a friend'),
      findsOneWidget,
    );
  });
}
