import 'package:agape_logos_game/features/multiplayer/domain/match_player.dart';
import 'package:agape_logos_game/features/multiplayer/presentation/widgets/fog_overlay.dart';
import 'package:agape_logos_game/features/multiplayer/presentation/widgets/frozen_letter_overlay.dart';
import 'package:agape_logos_game/features/multiplayer/presentation/widgets/match_timer.dart';
import 'package:agape_logos_game/features/multiplayer/presentation/widgets/opponent_hud.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('frozen overlay shows a frost icon per frozen slot', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: FrozenLetterOverlay(
          frozenSlots: {0, 2}, letterCount: 4, size: Size(260, 260),
        ),
      ),
    ));
    expect(find.byIcon(Icons.ac_unit_rounded), findsNWidgets(2));
  });

  testWidgets('frozen overlay renders nothing when no slots frozen',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: FrozenLetterOverlay(
          frozenSlots: {}, letterCount: 4, size: Size(260, 260),
        ),
      ),
    ));
    expect(find.byIcon(Icons.ac_unit_rounded), findsNothing);
  });

  testWidgets('fog overlay adds a BackdropFilter when active', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: FogOverlay(active: true, child: Text('board')),
      ),
    ));
    await tester.pump();
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.text('board'), findsOneWidget);
  });

  testWidgets('match timer formats remaining m:ss under an hour',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: MatchTimer(endsAt: 95000, nowMillis: 5000)),
    ));
    expect(find.text('1:30'), findsOneWidget);
  });

  testWidgets('match timer formats remaining h mm at/over an hour',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: MatchTimer(endsAt: 3700000 + 5000, nowMillis: 5000),
      ),
    ));
    expect(find.text('1h 01m'), findsOneWidget);
  });

  testWidgets('opponent HUD shows the server score, never a client one',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: OpponentHud(
          opponent: MatchPlayer(
            uid: 'b', displayName: 'Grace', avatarId: 'a', isGuest: false,
            ready: true, connected: true, score: 42, wordsFound: 5,
          ),
        ),
      ),
    ));
    expect(find.text('Grace'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('(5 words)'), findsOneWidget);
  });
}
