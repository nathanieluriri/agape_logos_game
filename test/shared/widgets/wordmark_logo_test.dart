// test/shared/widgets/wordmark_logo_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agape_logos_game/shared/widgets/wordmark_logo.dart';
import 'package:agape_logos_game/shared/widgets/lotus_mark.dart';

void main() {
  testWidgets('WordmarkLogo shows the lotus and the title', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Center(child: WordmarkLogo(float: false)),
    ));
    expect(find.byType(LotusMark), findsOneWidget);
    expect(find.text('ZEN WORD'), findsOneWidget);
  });
}
