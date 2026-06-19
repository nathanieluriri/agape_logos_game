// test/shared/widgets/lotus_mark_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:agape_logos_game/shared/widgets/lotus_mark.dart';

void main() {
  testWidgets('LotusMark renders the lotus svg asset', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Center(child: LotusMark(float: false)),
    ));
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
