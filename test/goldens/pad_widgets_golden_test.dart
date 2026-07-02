// Golden renders for the pad widgets (LilyPad in both shapes + PlayPadCluster).
//
// Regenerate the PNGs after a UI tweak with:
//   C:\flutter\bin\flutter test test/goldens/pad_widgets_golden_test.dart --update-goldens
// The images land next to this file. These widgets are provider-free, so no
// ProviderScope is needed; `disableAnimations` is forced on so the idle
// float/bob (an infinite AnimationController) settles instead of hanging
// pumpAndSettle.
import 'package:agape_logos_game/core/design/tokens/colors.dart';
import 'package:agape_logos_game/core/design/tokens/gradients.dart';
import 'package:agape_logos_game/core/design/tokens/spacing.dart';
import 'package:agape_logos_game/shared/widgets/lily_pad.dart';
import 'package:agape_logos_game/shared/widgets/play_pad_cluster.dart';
import 'package:agape_logos_game/shared/widgets/play_triangle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A pond-gradient stage of a fixed size, captured by [_stageKey].
const _stageKey = Key('pad-stage');

Widget _stage({
  required double width,
  required double height,
  required Widget child,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MediaQuery(
      // Force reduced-motion so LilyPadButton's idle float/bob controller
      // stays put and pumpAndSettle can complete.
      data: const MediaQueryData(disableAnimations: true),
      child: Center(
        child: SizedBox(
          key: _stageKey,
          width: width,
          height: height,
          child: DecoratedBox(
            decoration: const BoxDecoration(gradient: AppGradients.pond),
            child: Center(child: child),
          ),
        ),
      ),
    ),
  );
}

/// Renders at 3x device pixel ratio so the PNGs are crisp.
void _useSurface(WidgetTester tester, Size logical, {double dpr = 3.0}) {
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = Size(logical.width * dpr, logical.height * dpr);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('lily pad (green, notched)', (tester) async {
    _useSurface(tester, const Size(320, 320));
    await tester.pumpWidget(
      _stage(
        width: 300,
        height: 300,
        child: const LilyPad(
          size: 200,
          rotationDegrees: -135,
          palette: LilyPadPalette.green,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlayTriangle(size: 56),
              SizedBox(height: AppSpacing.sm),
              Text(
                'Lv.26',
                style: TextStyle(
                  color: AppColors.padLabel,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(_stageKey),
      matchesGoldenFile('lily_pad_green.png'),
    );
  });

  testWidgets('lily pad (blue, smooth)', (tester) async {
    _useSurface(tester, const Size(240, 240));
    await tester.pumpWidget(
      _stage(
        width: 220,
        height: 220,
        child: const LilyPad(
          size: 120,
          shape: PadShape.smooth,
          rotationDegrees: 25,
          palette: LilyPadPalette.bonusBlue,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(_stageKey),
      matchesGoldenFile('lily_pad_blue.png'),
    );
  });

  testWidgets('play pad cluster', (tester) async {
    _useSurface(tester, const Size(400, 400));
    await tester.pumpWidget(
      _stage(
        width: 390,
        height: 360,
        child: PlayPadCluster(
          nextLabel: 'Lv.26',
          onPlay: () {},
          secondaryIcon: const Icon(
            Icons.account_balance_wallet,
            size: 26,
            color: AppColors.padLabel,
          ),
          secondaryLabel: 'Withdraw',
          onSecondary: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(_stageKey),
      matchesGoldenFile('play_pad_cluster.png'),
    );
  });
}
