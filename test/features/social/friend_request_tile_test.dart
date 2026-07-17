import 'package:agape_logos_game/features/social/domain/friend_request.dart';
import 'package:agape_logos_game/features/social/presentation/widgets/friend_request_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test harness for FriendRequestTile at 320dp width (narrow phone).
Widget _buildTile({
  String name = 'Nathaniel uriri',
  String handle = 'nathanieluriri',
  bool busy = false,
}) =>
    MaterialApp(
      home: Scaffold(
        body: ConstrainedBox(
          constraints: const BoxConstraints.tightFor(width: 320),
          child: FriendRequestTile(
            request: FriendRequest(
              fromUid: 'u1',
              handle: handle,
              displayName: name,
              avatarId: 'avatar_01',
            ),
            busy: busy,
            onAccept: () {},
            onDecline: () {},
          ),
        ),
      ),
    );

void main() {
  group('FriendRequestTile at 320dp', () {
    testWidgets('renders without overflow errors', (tester) async {
      await tester.pumpWidget(_buildTile());
      // Verify no rendering errors occurred
      expect(tester.takeException(), isNull);
    });

    testWidgets('displays name and handle', (tester) async {
      await tester.pumpWidget(_buildTile(
        name: 'Nathaniel uriri',
        handle: 'nathanieluriri',
      ));
      expect(find.text('Nathaniel uriri'), findsOneWidget);
      expect(find.text('@nathanieluriri'), findsOneWidget);
    });

    testWidgets('shows both Accept and Decline buttons', (tester) async {
      await tester.pumpWidget(_buildTile());
      expect(find.bySemanticsLabel('Accept Nathaniel uriri'), findsOneWidget);
      expect(find.bySemanticsLabel('Decline Nathaniel uriri'), findsOneWidget);
    });

    testWidgets('buttons are rendered', (tester) async {
      await tester.pumpWidget(_buildTile());
      // Verify both buttons are present by checking their semantics labels
      expect(find.bySemanticsLabel('Accept Nathaniel uriri'), findsOneWidget);
      expect(find.bySemanticsLabel('Decline Nathaniel uriri'), findsOneWidget);
    });

    testWidgets('disables buttons when busy', (tester) async {
      await tester.pumpWidget(_buildTile(busy: true));
      expect(find.bySemanticsLabel('Accept Nathaniel uriri'), findsOneWidget);
      expect(find.bySemanticsLabel('Decline Nathaniel uriri'), findsOneWidget);
    });
  });

}
