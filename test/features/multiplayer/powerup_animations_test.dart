import 'package:agape_logos_game/features/multiplayer/application/match_providers.dart';
import 'package:agape_logos_game/features/multiplayer/presentation/widgets/active_effect_chips.dart';
import 'package:agape_logos_game/features/multiplayer/presentation/widgets/powerup_incoming_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PowerupIncomingBanner', () {
    testWidgets('shows caster name + powerup name and completes', (
      tester,
    ) async {
      var done = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PowerupIncomingBanner(
              data: const IncomingBannerData(
                casterName: 'Grace',
                powerupName: 'Fog Bank',
              ),
              onDone: () => done = true,
            ),
          ),
        ),
      );
      await tester.pump(); // drop-in starts
      await tester.pump(const Duration(milliseconds: 400)); // drop-in ends
      expect(find.text('Grace cast Fog Bank!'), findsOneWidget);
      expect(done, isFalse);

      // Holds for ~1500ms, then flies out over another ~320ms.
      await tester.pump(const Duration(milliseconds: 1600)); // hold elapses
      await tester.pump(const Duration(milliseconds: 400)); // fly-out ends
      expect(done, isTrue);
    });

    testWidgets('blocked variant shows the shield-shatter message', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PowerupIncomingBanner(
              data: const IncomingBannerData(
                casterName: 'Grace',
                powerupName: 'Fog Bank',
                blocked: true,
              ),
              onDone: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 320));
      expect(find.text('Shield blocked Fog Bank!'), findsOneWidget);
      expect(find.text('Grace cast Fog Bank!'), findsNothing);
    });
  });

  group('ActiveEffectChips', () {
    const now = 10000;
    final effects = MatchActiveEffects(
      fog: true,
      fogUntil: DateTime.fromMillisecondsSinceEpoch(now + 4000),
      frozenLetter: 'A',
      freezeUntil: DateTime.fromMillisecondsSinceEpoch(now + 2500),
      doublePoints: true,
      warded: true,
      wardUntil: DateTime.fromMillisecondsSinceEpoch(now + 9000),
      shieldArmed: true,
    );

    testWidgets('renders remaining-seconds chips from a fake effects state', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActiveEffectChips(effects: effects, nowMillis: now),
          ),
        ),
      );

      expect(find.text('Fog 4s'), findsOneWidget);
      expect(find.text('Frozen 3s'), findsOneWidget); // ceil(2500ms) -> 3s
      expect(find.text('2x points'), findsOneWidget);
      expect(find.text('Warded 9s'), findsOneWidget);
      expect(find.text('Shield'), findsOneWidget);
    });

    testWidgets('renders nothing for an empty effects state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ActiveEffectChips(
              effects: MatchActiveEffects.empty,
              nowMillis: now,
            ),
          ),
        ),
      );
      expect(find.byType(Wrap), findsNothing);
    });

    testWidgets('drops a chip once its expiry has passed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActiveEffectChips(effects: effects, nowMillis: now + 5000),
          ),
        ),
      );
      // fog (until now+4000) and freeze (until now+2500) have both lapsed;
      // ward (until now+9000) and the armed-until-consumed shield have not.
      expect(find.textContaining('Fog'), findsNothing);
      expect(find.textContaining('Frozen'), findsNothing);
      expect(find.text('Shield'), findsOneWidget);
      expect(find.textContaining('Warded'), findsOneWidget);
    });
  });
}
