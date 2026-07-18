// test/app/resume_refresh_gate_test.dart
import 'package:agape_logos_game/app/resume_refresh_gate.dart';
import 'package:agape_logos_game/features/multiplayer/application/resume_providers.dart';
import 'package:agape_logos_game/features/multiplayer/domain/active_match.dart';
import 'package:agape_logos_game/features/social/application/social_providers.dart';
import 'package:agape_logos_game/features/social/domain/match_history_entry.dart';
import 'package:agape_logos_game/features/store/application/store_providers.dart';
import 'package:agape_logos_game/features/store/domain/store_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'resuming the app refetches the registered stale providers, '
    'pausing/going inactive does not',
    (tester) async {
      var activeMatchesFetches = 0;
      var matchHistoryFetches = 0;
      var storeCatalogFetches = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeMatchesProvider.overrideWith((ref) {
              activeMatchesFetches++;
              return Future<List<ActiveMatch>>.value(const <ActiveMatch>[]);
            }),
            matchHistoryProvider.overrideWith((ref) {
              matchHistoryFetches++;
              return Future<List<MatchHistoryEntry>>.value(
                const <MatchHistoryEntry>[],
              );
            }),
            storeCatalogProvider.overrideWith((ref) {
              storeCatalogFetches++;
              return Future<List<StoreItem>>.value(const <StoreItem>[]);
            }),
          ],
          child: const MaterialApp(
            home: ResumeRefreshGate(
              child: Text('content', textDirection: TextDirection.ltr),
            ),
          ),
        ),
      );
      await tester.pump();

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.text('content')),
      );

      // Establish the initial fetch for each registered provider.
      container.read(activeMatchesProvider);
      container.read(matchHistoryProvider);
      container.read(storeCatalogProvider);
      await tester.pump();

      expect(activeMatchesFetches, 1);
      expect(matchHistoryFetches, 1);
      expect(storeCatalogFetches, 1);

      // Backgrounding the app must not touch any of the registered providers.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      container.read(activeMatchesProvider);
      container.read(matchHistoryProvider);
      container.read(storeCatalogProvider);
      await tester.pump();

      expect(activeMatchesFetches, 1);
      expect(matchHistoryFetches, 1);
      expect(storeCatalogFetches, 1);

      // Foregrounding again invalidates the whole registered set, so the next
      // read refetches each one.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      container.read(activeMatchesProvider);
      container.read(matchHistoryProvider);
      container.read(storeCatalogProvider);
      await tester.pump();

      expect(activeMatchesFetches, 2);
      expect(matchHistoryFetches, 2);
      expect(storeCatalogFetches, 2);
    },
  );

  testWidgets('removes its lifecycle observer on dispose', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ResumeRefreshGate(
            child: Text('content', textDirection: TextDirection.ltr),
          ),
        ),
      ),
    );
    await tester.pump();

    // Unmounting the gate (e.g. a route swap above it in a differently
    // structured tree) must not leave a dangling observer that fires a
    // callback against a disposed widget.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    // No AppLifecycleState after unmount should throw; if the observer were
    // still registered, invalidating against a disposed ref would throw.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
  });
}
