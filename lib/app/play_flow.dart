// lib/app/play_flow.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_providers.dart';
import '../features/auth/presentation/widgets/auth_sheet.dart';
import '../features/multiplayer/presentation/widgets/multiplayer_sheet.dart';
import '../game/ambient/ambient_providers.dart' show ambientPausedProvider;

/// Shared Play action for the home and level-complete pages: if the player is
/// not signed in, prompt sign-in first; then pause the pond ambient, open the
/// game, and resume when the player returns (the push future completes on pop).
Future<void> startPlayFlow(BuildContext context, WidgetRef ref) async {
  if (ref.read(currentUserProvider) == null) {
    await showAuthSheet(context);
    if (!context.mounted) return;
    if (ref.read(currentUserProvider) == null) return;
  }
  ref.read(ambientPausedProvider.notifier).pause(true);
  await context.push('/game');
  if (context.mounted) {
    ref.read(ambientPausedProvider.notifier).pause(false);
  }
}

/// Multiplayer entry: sign the player in first (guests welcome, since
/// multiplayer is online anyway), then let them pick create/join on the
/// chooser sheet and open the matching form. Mirrors [startPlayFlow] but does
/// not pause the pond ambient (the sheet keeps the pond behind it).
Future<void> startMultiplayerFlow(BuildContext context, WidgetRef ref) async {
  if (ref.read(currentUserProvider) == null) {
    await showAuthSheet(context);
    if (!context.mounted) return;
    if (ref.read(currentUserProvider) == null) return;
  }
  final choice = await showMultiplayerSheet(context);
  if (choice == null || !context.mounted) return;
  final mode = choice == MultiplayerChoice.create ? 'create' : 'join';
  await context.push('/multiplayer?mode=$mode');
}
