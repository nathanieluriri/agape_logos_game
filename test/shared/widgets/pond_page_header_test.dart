// test/shared/widgets/pond_page_header_test.dart
import 'package:agape_logos_game/shared/widgets/glyphs/pond_glyph.dart';
import 'package:agape_logos_game/shared/widgets/pond_icon_button.dart';
import 'package:agape_logos_game/shared/widgets/pond_page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('header shows the title and a painted back chevron',
      (tester) async {
    // bySemanticsLabel needs a live semantics tree in widget tests.
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PondPageHeader(title: 'Store')),
      ),
    );
    expect(find.text('Store'), findsOneWidget);
    expect(find.bySemanticsLabel('Back'), findsOneWidget);
    final icon = tester.widget<PondIcon>(find.byType(PondIcon));
    expect(icon.glyph, PondGlyph.chevronLeft);
    semantics.dispose();
  });

  testWidgets('onBack overrides the default pop behaviour', (tester) async {
    var called = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PondPageHeader(title: 'Lobby', onBack: () => called = true),
        ),
      ),
    );
    await tester.tap(find.byType(PondIconButton));
    await tester.pump();
    expect(called, isTrue);
  });
}
