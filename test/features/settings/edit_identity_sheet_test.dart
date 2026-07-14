import 'dart:async';

import 'package:agape_logos_game/features/auth/application/auth_providers.dart';
import 'package:agape_logos_game/features/auth/domain/auth_user.dart';
import 'package:agape_logos_game/features/profile/application/profile_providers.dart';
import 'package:agape_logos_game/features/profile/domain/handle_outcome.dart';
import 'package:agape_logos_game/features/profile/domain/profile.dart';
import 'package:agape_logos_game/features/profile/domain/profile_repository.dart';
import 'package:agape_logos_game/features/settings/presentation/widgets/identity_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Profile _profile({
  String displayName = 'River Frog',
  String handle = 'riverfrog',
}) => Profile(
  uid: 'u1',
  displayName: displayName,
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

/// Stands in for the server + Drift cache. `setHandle` mutates the server-side
/// profile (so a later `fetch` sees the new handle), `updateDisplayName` writes
/// the cache optimistically (so `watch` emits it at once) without touching the
/// server copy, exactly like the optimistic queue does.
class _FakeRepo implements ProfileRepository {
  _FakeRepo(this._server) : _cached = _server;

  Profile _server;
  Profile _cached;
  final _cache = StreamController<Profile?>.broadcast();

  int setHandleCalls = 0;
  String? lastHandle;

  @override
  Future<Profile?> fetch(String uid) async => _server;

  @override
  Stream<Profile?> watch(String uid) async* {
    yield _cached;
    yield* _cache.stream;
  }

  @override
  Future<int?> fetchCoins(String uid) async => _server.coins;

  @override
  Future<void> addCoinsLocally(String uid, int delta) async {}

  @override
  Future<void> advanceLevelLocally(String uid, int level) async {}

  @override
  Future<void> updateDisplayName(String uid, String displayName) async {
    // Optimistic: cache only. The server keeps the old name until the queue
    // flushes.
    _cached = _cached.copyWith(displayName: displayName);
    _cache.add(_cached);
  }

  @override
  Future<void> clear() async {}

  @override
  Future<HandleOutcome> setHandle(String handle) async {
    setHandleCalls++;
    lastHandle = handle;
    _server = _server.copyWith(handle: handle);
    return HandleChanged(handle);
  }
}

Future<ProviderContainer> _pumpCard(WidgetTester tester, _FakeRepo repo) async {
  final container = ProviderContainer(
    overrides: [
      authStateProvider.overrideWith(
        (ref) => Stream<AuthUser?>.value(const AuthUser(uid: 'u1')),
      ),
      profileRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(container.dispose);
  // The real bootstrap path: the auth listener calls load() once.
  await container.read(profileControllerProvider.notifier).load('u1');
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: IdentityCard())),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> _openSheetAndSave(
  WidgetTester tester, {
  String? name,
  String? handle,
}) async {
  await tester.tap(find.byType(IdentityCard));
  await tester.pumpAndSettle();
  final fields = find.byType(TextFormField);
  if (name != null) await tester.enterText(fields.at(0), name);
  if (handle != null) await tester.enterText(fields.at(1), handle);
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a successful handle change shows the NEW handle on the card', (
    tester,
  ) async {
    // Regression test for the invalidate() bug: ProfileController.build()
    // returns null and only load() populates it, so invalidating the provider
    // blanked the card that the feature exists to show.
    final repo = _FakeRepo(_profile());
    await _pumpCard(tester, repo);
    expect(find.text('@riverfrog'), findsOneWidget);

    await _openSheetAndSave(tester, handle: 'pondking');

    expect(repo.lastHandle, 'pondking');
    expect(find.text('@pondking'), findsOneWidget);
    expect(find.text('River Frog'), findsOneWidget);
    expect(find.text('-'), findsNothing);
  });

  testWidgets('a rename shows the new name and does not revert to the server one', (
    tester,
  ) async {
    final repo = _FakeRepo(_profile());
    await _pumpCard(tester, repo);

    await _openSheetAndSave(tester, name: 'Pond King');

    expect(find.text('Pond King'), findsOneWidget);
    expect(find.text('River Frog'), findsNothing);
    expect(find.text('@riverfrog'), findsOneWidget);
  });

  testWidgets('clearing the handle field never fires a handle claim', (
    tester,
  ) async {
    final repo = _FakeRepo(_profile());
    await _pumpCard(tester, repo);

    await _openSheetAndSave(tester, handle: '');

    expect(repo.setHandleCalls, 0);
    expect(find.text('@riverfrog'), findsOneWidget);
  });
}
