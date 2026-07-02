// Golden renders for the game-feature widgets (letter wheel, word board,
// top bar, combo banner, formed-word pill, wheel action button).
//
// Regenerate the PNGs after a UI tweak with:
//   C:\flutter\bin\flutter test test/goldens/game_widgets_golden_test.dart --update-goldens
// The images land next to this file. These widgets are provider-free, so no
// ProviderScope is needed; `disableAnimations` is forced on so idle/press
// AnimationControllers settle instead of hanging pumpAndSettle.
import 'package:agape_logos_game/core/design/tokens/gradients.dart';
import 'package:agape_logos_game/features/game/presentation/widgets/combo_banner.dart';
import 'package:agape_logos_game/features/game/presentation/widgets/formed_word_pill.dart';
import 'package:agape_logos_game/features/game/presentation/widgets/game_top_bar.dart';
import 'package:agape_logos_game/features/game/presentation/widgets/letter_wheel.dart';
import 'package:agape_logos_game/features/game/presentation/widgets/wheel_action_button.dart';
import 'package:agape_logos_game/features/game/presentation/widgets/word_board.dart';
import 'package:agape_logos_game/features/puzzles/domain/puzzle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A pond-gradient stage of a fixed size, captured by [_stageKey].
const _stageKey = Key('game-widget-stage');

Widget _stage({
  required double width,
  required double height,
  required Widget child,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MediaQuery(
      // Force reduced-motion so idle float/press AnimationControllers stay
      // put and pumpAndSettle can complete.
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
  testWidgets('game top bar', (tester) async {
    _useSurface(tester, const Size(420, 120));
    await tester.pumpWidget(
      _stage(
        width: 400,
        height: 100,
        child: GameTopBar(
          level: 26,
          coins: 4820,
          onBack: () {},
          onDictionary: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(_stageKey),
      matchesGoldenFile('game_top_bar.png'),
    );
  });

  testWidgets('letter wheel', (tester) async {
    _useSurface(tester, const Size(280, 280));
    await tester.pumpWidget(
      _stage(
        width: 260,
        height: 260,
        child: LetterWheel(
          letters: const ['F', 'I', 'T', 'S', 'A', 'R'],
          selected: const [0, 1, 2],
          onTouch: (_) {},
          onEnd: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(_stageKey),
      matchesGoldenFile('letter_wheel.png'),
    );
  });

  testWidgets('word board', (tester) async {
    _useSurface(tester, const Size(320, 260));
    await tester.pumpWidget(
      _stage(
        width: 300,
        height: 240,
        child: WordBoard(
          targets: const [
            PuzzleAnswer(word: 'FIT', length: 3, definition: null),
            PuzzleAnswer(word: 'FAIR', length: 4, definition: null),
            PuzzleAnswer(word: 'FRIST', length: 5, definition: null),
          ],
          found: const {'FIT'},
          revealed: const {'FAIR': 2},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(_stageKey),
      matchesGoldenFile('word_board.png'),
    );
  });

  testWidgets('formed word pill', (tester) async {
    _useSurface(tester, const Size(200, 100));
    await tester.pumpWidget(
      _stage(width: 180, height: 80, child: const FormedWordPill(word: 'FIT')),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(_stageKey),
      matchesGoldenFile('formed_word_pill.png'),
    );
  });

  testWidgets('combo banner', (tester) async {
    _useSurface(tester, const Size(260, 140));
    await tester.pumpWidget(
      _stage(
        width: 240,
        height: 120,
        child: const ComboBanner(praise: 'Expert!', combo: 3),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(_stageKey),
      matchesGoldenFile('combo_banner.png'),
    );
  });

  testWidgets('wheel action button (enabled with badge)', (tester) async {
    _useSurface(tester, const Size(120, 120));
    await tester.pumpWidget(
      _stage(
        width: 100,
        height: 100,
        child: WheelActionButton(
          icon: Icons.lightbulb_outline,
          semanticLabel: 'Hint',
          onTap: () {},
          badge: 2,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(_stageKey),
      matchesGoldenFile('wheel_action_button_enabled.png'),
    );
  });

  testWidgets('wheel action button (disabled)', (tester) async {
    _useSurface(tester, const Size(120, 120));
    await tester.pumpWidget(
      _stage(
        width: 100,
        height: 100,
        child: WheelActionButton(
          icon: Icons.shuffle,
          semanticLabel: 'Shuffle',
          onTap: () {},
          enabled: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(_stageKey),
      matchesGoldenFile('wheel_action_button_disabled.png'),
    );
  });
}
