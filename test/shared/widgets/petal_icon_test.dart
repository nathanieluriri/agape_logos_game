import 'package:agape_logos_game/core/design/tokens/sizing.dart';
import 'package:agape_logos_game/shared/widgets/petal_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders exactly one branding-petal SVG at the given width',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: PetalIcon(size: 40))),
      ),
    );
    await tester.pump();

    expect(find.byType(PetalIcon), findsOneWidget);
    final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(svg.width, 40);
    // Height is left null so it follows the SVG's intrinsic aspect ratio.
    expect(svg.height, isNull);
    // The canonical asset path lives in one place now.
    expect(PetalIcon.asset, 'assets/branding/coin_petal.svg');
  });

  testWidgets('defaults to the medium sizing token', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PetalIcon())),
    );
    await tester.pump();

    final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(svg.width, AppSizing.petalIconMd);
  });
}
