// test/shared/widgets/pond_progress_track_test.dart
import 'package:agape_logos_game/shared/widgets/pond_progress_track.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('builds across the fraction range without overflow', (tester) async {
    for (final f in const [0.0, 0.01, 0.5, 1.0]) {
      await tester.pumpWidget(_host(PondProgressTrack(fraction: f)));
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byType(PondProgressTrack), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('static track (no shimmer) settles', (tester) async {
    await tester.pumpWidget(_host(const PondProgressTrack(fraction: 0.6)));
    // No perpetual ticker in the default configuration.
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('shimmer variant parks under reduced motion', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Scaffold(
          body: Center(child: PondProgressTrack(fraction: 0.6, shimmer: true)),
        ),
      ),
    ));
    // Reduced motion stops the sweep, so the tree settles.
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
