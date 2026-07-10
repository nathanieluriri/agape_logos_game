// test/features/level_complete/level_progress_bar_test.dart
import 'package:agape_logos_game/core/design/tokens/durations.dart';
import 'package:agape_logos_game/features/level_complete/presentation/widgets/level_progress_bar.dart';
import 'package:agape_logos_game/shared/widgets/pond_progress_track.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {bool reduceMotion = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  testWidgets('shows label and counts the numeral up to the real fraction',
      (tester) async {
    await tester.pumpWidget(_host(
      const LevelProgressBar(
        label: 'Level 3 Completed!',
        wordsFound: 5,
        totalWords: 8,
      ),
    ));
    // Mid-animation the numeral is still climbing (not yet 5/8).
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('Level 3 Completed!'), findsOneWidget);

    // After the fill window it settles on the real fraction text.
    await tester.pump(AppDurations.slow + const Duration(milliseconds: 200));
    expect(find.text('5/8'), findsOneWidget);

    // The fill reached the real fraction (5/8 = 0.625).
    final track =
        tester.widget<PondProgressTrack>(find.byType(PondProgressTrack));
    expect(track.fraction, closeTo(0.625, 0.02));
  });

  testWidgets('full clear reaches 8/8 and settles (one-shot bloom)',
      (tester) async {
    await tester.pumpWidget(_host(
      const LevelProgressBar(
        label: 'Level 3 Completed!',
        wordsFound: 8,
        totalWords: 8,
      ),
    ));
    await tester.pump();
    await tester.pump(AppDurations.slow + const Duration(milliseconds: 400));
    expect(find.text('8/8'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion shows the final state immediately', (tester) async {
    await tester.pumpWidget(_host(
      const LevelProgressBar(
        label: 'Level 3 Completed!',
        wordsFound: 5,
        totalWords: 8,
      ),
      reduceMotion: true,
    ));
    await tester.pump();
    expect(find.text('5/8'), findsOneWidget);
    final track =
        tester.widget<PondProgressTrack>(find.byType(PondProgressTrack));
    expect(track.fraction, closeTo(0.625, 0.001));
  });
}
