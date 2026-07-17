import 'package:agape_logos_game/core/design/tokens/colors.dart';
import 'package:agape_logos_game/core/design/tokens/gradients.dart';
import 'package:agape_logos_game/shared/widgets/lily_pad.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('coral pad renders with the coral tokens', (tester) async {
    expect(LilyPadPalette.coral.fillGradient, AppGradients.lilyCoral);
    expect(LilyPadPalette.coral.underside, AppColors.lilyCoralUnder);
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: LilyPad(size: 100, palette: LilyPadPalette.coral),
    ));
    expect(find.byType(LilyPad), findsOneWidget);
  });
}
