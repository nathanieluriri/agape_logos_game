// test/shared/widgets/glyphs/pond_glyph_test.dart
import 'package:agape_logos_game/shared/widgets/glyphs/pond_glyph.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('every glyph paints without throwing', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Wrap(
          children: [
            for (final g in PondGlyph.values) PondIcon(g, size: 44),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(PondIcon), findsNWidgets(PondGlyph.values.length));
  });

  testWidgets('PondIcon honours its size', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: PondIcon(PondGlyph.book, size: 52)),
      ),
    );
    final box = tester.getSize(find.byType(PondIcon));
    expect(box.width, 52);
    expect(box.height, 52);
  });

  testWidgets('PondIcon excludes its painting from semantics', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: PondIcon(PondGlyph.versus),
      ),
    );
    expect(find.byType(ExcludeSemantics), findsOneWidget);
  });
}
