import 'package:agape_logos_game/features/auth/application/auth_providers.dart';
import 'package:agape_logos_game/features/auth/domain/auth_user.dart';
import 'package:agape_logos_game/features/profile/application/profile_providers.dart';
import 'package:agape_logos_game/features/profile/domain/profile.dart';
import 'package:agape_logos_game/features/settings/presentation/widgets/identity_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Profile _profile({String handle = 'riverfrog'}) => Profile(
      uid: 'u1',
      displayName: 'River Frog',
      avatarId: 'a1',
      locale: 'en',
      soundEnabled: true,
      musicEnabled: true,
      highestLevel: 3,
      totalScore: 120,
      coins: 40,
      createdAt: 0,
      updatedAt: 0,
      handle: handle,
    );

/// Fake for the live `GET /me` controller (the handle is NOT in Drift, so the
/// card must read it from here).
class _FakeProfileController extends ProfileController {
  _FakeProfileController(this.profile);
  final Profile profile;

  @override
  Future<Profile?> build() async => profile;
}

Widget _harness(Profile profile) => ProviderScope(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => Stream<AuthUser?>.value(const AuthUser(uid: 'u1')),
        ),
        profileControllerProvider
            .overrideWith(() => _FakeProfileController(profile)),
      ],
      child: const MaterialApp(home: Scaffold(body: IdentityCard())),
    );

void main() {
  testWidgets('renders the display name and the @handle', (tester) async {
    await tester.pumpWidget(_harness(_profile()));
    await tester.pumpAndSettle();

    expect(find.text('River Frog'), findsOneWidget);
    expect(find.text('@riverfrog'), findsOneWidget);
  });

  testWidgets('copy puts the @handle on the clipboard', (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(_harness(_profile()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Copy handle'));
    await tester.pumpAndSettle();

    final copy = calls.firstWhere((c) => c.method == 'Clipboard.setData');
    expect((copy.arguments as Map)['text'], '@riverfrog');
    expect(find.text('Handle copied'), findsOneWidget);
  });

  testWidgets('an empty handle renders a dash, never a lonely @',
      (tester) async {
    await tester.pumpWidget(_harness(_profile(handle: '')));
    await tester.pumpAndSettle();

    expect(find.text('-'), findsOneWidget);
    expect(find.text('@'), findsNothing);
  });
}
