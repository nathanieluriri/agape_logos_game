import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:agape_logos_game/core/storage/storage_providers.dart';
import 'package:agape_logos_game/features/multiplayer/presentation/widgets/powerup_tutorial_overlay.dart';
import 'package:agape_logos_game/features/settings/application/settings_providers.dart';
import 'package:agape_logos_game/features/tutorial/presentation/widgets/tutorial_message_pill.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Static settings row (see tutorial_overlay_test.dart for why the live Drift
/// stream is not used to drive the widget): the real DB still backs writes.
GameSettingsRow _row({required bool powerupSeen}) => GameSettingsRow(
      id: 0,
      soundEffects: true,
      music: true,
      notifications: true,
      haptics: true,
      tutorialSeen: true,
      powerupTutorialSeen: powerupSeen,
    );

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => db.close());

  final offenseKey = GlobalKey();
  final defenseKey = GlobalKey();
  final slotKey = GlobalKey();

  Widget harness({
    required bool powerupSeen,
    void Function(bool open)? onWheel,
  }) {
    var wheelOpen = false;
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        settingsProvider.overrideWith(
          (ref) => Stream.value(_row(powerupSeen: powerupSeen)),
        ),
      ],
      child: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => Stack(
                children: [
                  Positioned(
                    left: 10,
                    top: 100,
                    child: SizedBox(key: offenseKey, width: 40, height: 40),
                  ),
                  Positioned(
                    left: 10,
                    top: 160,
                    child: SizedBox(key: defenseKey, width: 40, height: 40),
                  ),
                  if (wheelOpen)
                    Positioned(
                      left: 100,
                      top: 300,
                      child: SizedBox(key: slotKey, width: 48, height: 48),
                    ),
                  Positioned.fill(
                    child: PowerupTutorialOverlay(
                      offenseKey: offenseKey,
                      defenseKey: defenseKey,
                      wheelSlotKey: slotKey,
                      onOpenOffenseWheel: () {
                        setState(() => wheelOpen = true);
                        onWheel?.call(true);
                      },
                      onCloseWheel: () {
                        setState(() => wheelOpen = false);
                        onWheel?.call(false);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> pumpSteps(WidgetTester tester, Widget app) async {
    await tester.pumpWidget(app);
    await tester.pump(); // settings stream emits
    await tester.pump(const Duration(milliseconds: 50)); // start + rects
  }

  Future<void> tapAdvance(WidgetTester tester) async {
    await tester.tapAt(const Offset(200, 500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('unseen flag: shows and advances through the 3 steps',
      (tester) async {
    final wheelEvents = <bool>[];
    await pumpSteps(
      tester,
      harness(powerupSeen: false, onWheel: wheelEvents.add),
    );

    // Step 1: offense button.
    expect(find.byType(TutorialMessagePill), findsOneWidget);
    expect(
      find.text('Attack your opponent', findRichText: true),
      findsOneWidget,
    );

    // Step 2: the wheel auto-opens and the slot is spotlighted.
    await tapAdvance(tester);
    expect(wheelEvents, [true]);
    expect(
      find.text(
        'Drag a powerup onto the board to use it',
        findRichText: true,
      ),
      findsOneWidget,
    );

    // Step 3: wheel closes, defense button.
    await tapAdvance(tester);
    expect(wheelEvents, [true, false]);
    expect(
      find.text('Protect yourself the same way', findRichText: true),
      findsOneWidget,
    );

    // Final tap dismisses and persists the flag exactly once.
    await tapAdvance(tester);
    expect(find.byType(TutorialMessagePill), findsNothing);
    final row = await (db.select(db.gameSettings)
          ..where((t) => t.id.equals(0)))
        .getSingle();
    expect(row.powerupTutorialSeen, isTrue);
  });

  testWidgets('seen flag: never shows', (tester) async {
    await pumpSteps(tester, harness(powerupSeen: true));
    expect(find.byType(TutorialMessagePill), findsNothing);
  });

  testWidgets('Skip dismisses immediately and persists the flag',
      (tester) async {
    await pumpSteps(tester, harness(powerupSeen: false));
    expect(find.text('Skip'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(TutorialMessagePill), findsNothing);
    final row = await (db.select(db.gameSettings)
          ..where((t) => t.id.equals(0)))
        .getSingle();
    expect(row.powerupTutorialSeen, isTrue);
  });
}
