import 'package:agape_logos_game/features/home/presentation/widgets/progress_sync_notice.dart';
import 'package:agape_logos_game/features/profile/application/progress_sync_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(bool failed) => ProviderScope(
      overrides: [
        progressSyncFailedProvider.overrideWith((ref) => Stream.value(failed)),
      ],
      child: const MaterialApp(home: Scaffold(body: ProgressSyncNotice())),
    );

void main() {
  testWidgets('hidden when there is no failed progress', (tester) async {
    await tester.pumpWidget(_host(false));
    await tester.pump();
    expect(find.textContaining('save', findRichText: true), findsNothing);
    expect(find.byType(SizedBox), findsWidgets); // renders nothing visible
  });

  testWidgets('shows the notice + retry when progress failed to sync',
      (tester) async {
    await tester.pumpWidget(_host(true));
    await tester.pump();
    expect(find.text('Some progress did not save'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
