import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/application/settings_providers.dart';

/// The three beats of the first-time powerup walkthrough on the match page.
enum PowerupTutorialStep { offense, wheelDrag, defense }

/// Drives the one-time powerup spotlight shown the first time a player is in
/// an active match. Mirrors [TutorialController]'s persistence pattern: the
/// `powerupTutorialSeen` settings flag is written exactly once, on completion
/// or dismissal, straight through the settings DAO.
///
/// State is null whenever the tutorial is not showing. The overlay (mounted by
/// the match page only while a match is actually playable) calls [maybeStart];
/// the controller itself never watches match state, so it stays feature-local.
class PowerupTutorialController extends Notifier<PowerupTutorialStep?> {
  /// Blocks restarts within this app run once finished or skipped; the
  /// persisted flag covers the next run.
  bool _dismissed = false;

  @override
  PowerupTutorialStep? build() {
    // Re-check when the settings row lands after the overlay's first ask.
    ref.listen(settingsProvider, (prev, next) => maybeStart());
    return null;
  }

  /// Starts the walkthrough if the player has never seen it. Safe to call on
  /// every overlay mount: it is a no-op once running, dismissed, or seen.
  void maybeStart() {
    if (_dismissed || state != null) return;
    final settings = ref.read(settingsProvider).value;
    if (settings == null || settings.powerupTutorialSeen) return;
    state = PowerupTutorialStep.offense;
  }

  /// A tap anywhere advances; the tap on the last step completes and persists.
  void advance() {
    switch (state) {
      case PowerupTutorialStep.offense:
        state = PowerupTutorialStep.wheelDrag;
      case PowerupTutorialStep.wheelDrag:
        state = PowerupTutorialStep.defense;
      case PowerupTutorialStep.defense:
        dismiss();
      case null:
        break;
    }
  }

  /// Hide immediately and never show again (Skip, or the final advance).
  void dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    state = null;
    unawaited(ref.read(settingsDaoProvider).setPowerupTutorialSeen(true));
  }
}

final powerupTutorialProvider =
    NotifierProvider<PowerupTutorialController, PowerupTutorialStep?>(
  PowerupTutorialController.new,
);
