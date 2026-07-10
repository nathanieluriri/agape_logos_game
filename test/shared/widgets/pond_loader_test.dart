// test/shared/widgets/pond_loader_test.dart
import 'package:agape_logos_game/shared/widgets/pond_loader.dart';
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
  testWidgets('indeterminate loader builds and shows its label', (tester) async {
    await tester.pumpWidget(_host(const PondLoader(label: 'Loading the store')));
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('Loading the store'), findsOneWidget);
    expect(find.byType(PondProgressTrack), findsOneWidget);
    expect(tester.takeException(), isNull);
    // NOTE: indeterminate mode loops forever by design, so this test never calls
    // pumpAndSettle. It disposes cleanly at tearDown.
  });

  testWidgets('determinate loader reflects the given progress', (tester) async {
    await tester.pumpWidget(
      _host(const PondLoader(label: 'Loading', progress: 0.5)),
    );
    await tester.pump(const Duration(milliseconds: 16));
    final track =
        tester.widget<PondProgressTrack>(find.byType(PondProgressTrack));
    expect(track.fraction, closeTo(0.5, 0.001));

    // Update to a higher value and confirm the track follows.
    await tester.pumpWidget(
      _host(const PondLoader(label: 'Loading', progress: 0.9)),
    );
    await tester.pump(const Duration(milliseconds: 16));
    final track2 =
        tester.widget<PondProgressTrack>(find.byType(PondProgressTrack));
    expect(track2.fraction, closeTo(0.9, 0.001));
  });

  testWidgets('reduced motion parks the loader (settles)', (tester) async {
    await tester.pumpWidget(
      _host(const PondLoader(label: 'Loading'), reduceMotion: true),
    );
    // No perpetual ticker under reduced motion, so the tree settles.
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(PondProgressTrack), findsOneWidget);
  });

  testWidgets('determinate at full fires a one-shot bloom and settles',
      (tester) async {
    await tester.pumpWidget(
      _host(const PondLoader(label: 'Ready', progress: 1.0)),
    );
    // The bloom is one-shot; the fill is static (external progress), so settle.
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
