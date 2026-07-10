// test/shared/widgets/lotus_bloom_test.dart
import 'package:agape_logos_game/shared/widgets/lotus_bloom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('plays once and settles (no perpetual ticker)', (tester) async {
    var ended = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(child: LotusBloom(onEnd: () => ended = true)),
      ),
    ));
    // A one-shot bloom completes, so the tree settles rather than looping.
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(ended, isTrue);
  });

  testWidgets('reduced motion is inert and still reports end', (tester) async {
    var ended = false;
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(
          body: Center(child: LotusBloom(onEnd: () => ended = true)),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(ended, isTrue);
  });
}
