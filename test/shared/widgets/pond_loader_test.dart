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

double _trackFraction(WidgetTester tester) =>
    tester.widget<PondProgressTrack>(find.byType(PondProgressTrack)).fraction;

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

  testWidgets('indeterminate fill only ever moves forward', (tester) async {
    await tester.pumpWidget(_host(const PondLoader(label: 'Loading')));
    var last = 0.0;
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      final f = _trackFraction(tester);
      expect(f, greaterThanOrEqualTo(last),
          reason: 'fill went backward at sample $i');
      last = f;
    }
    // It genuinely advanced, and never claims completion on its own.
    expect(last, greaterThan(0.5));
    expect(last, lessThan(1.0));
  });

  testWidgets('handoff to a lower determinate value never moves backward',
      (tester) async {
    await tester.pumpWidget(_host(const PondLoader(label: 'Loading')));
    await tester.pump(const Duration(seconds: 3));
    final before = _trackFraction(tester);
    expect(before, greaterThan(0.5)); // trickle is well underway
    // Same widget type: State (and the latch) is preserved across rebuild.
    await tester.pumpWidget(
      _host(const PondLoader(label: 'Loading', progress: 0.1)),
    );
    await tester.pump(const Duration(milliseconds: 16));
    expect(_trackFraction(tester), greaterThanOrEqualTo(before));
  });

  testWidgets('completion eases the shown fill to 1.0 and settles',
      (tester) async {
    await tester.pumpWidget(
      _host(const PondLoader(label: 'Loading', progress: 0.4)),
    );
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pumpWidget(
      _host(const PondLoader(label: 'Loading', progress: 1.0)),
    );
    await tester.pumpAndSettle();
    expect(_trackFraction(tester), 1.0);
    expect(tester.takeException(), isNull);
  });
}
