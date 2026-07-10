// test/shared/widgets/pond_sheet_test.dart
import 'package:agape_logos_game/shared/widgets/pond_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('showPondSheet presents the child and returns the pop value',
      (tester) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showPondSheet<String>(
                  context: context,
                  builder: (_) => Builder(
                    builder: (sheetContext) => TextButton(
                      onPressed: () =>
                          Navigator.of(sheetContext).pop('picked'),
                      child: const Text('Pick'),
                    ),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Pick'), findsOneWidget);
    expect(find.byType(PondSheetScaffold), findsOneWidget);
    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();
    expect(result, 'picked');
  });

  testWidgets('dismissing via the barrier returns null', (tester) async {
    String? result = 'sentinel';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showPondSheet<String>(
                  context: context,
                  builder: (_) => const Text('Body'),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10)); // barrier
    await tester.pumpAndSettle();
    expect(result, isNull);
  });
}
