// test/shared/widgets/pond_stage_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agape_logos_game/shared/widgets/pond_stage.dart';
import 'package:agape_logos_game/core/design/tokens/sizing.dart';

void main() {
  testWidgets('PondStage constrains content to the stage max width on web sizes',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: PondStage(child: Container(key: const Key('content')))),
    ));
    final box = tester.getSize(find.byKey(const Key('content')));
    expect(box.width, lessThanOrEqualTo(AppSizing.stageMaxWidth));
  });
}
