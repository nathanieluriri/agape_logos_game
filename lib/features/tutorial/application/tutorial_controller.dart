import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/application/game_controller.dart';
import '../../settings/application/settings_providers.dart';
import 'tutorial_state.dart';

/// Drives the first-play tutorial. Watches settings and the live game session,
/// starts the guided trace on a fresh install (tutorialSeen false, session
/// loaded, nothing found yet), advances as target words land in the session's
/// found set, and persists tutorialSeen exactly once via [_markSeen].
///
/// State is null whenever no tutorial is showing. The UI only reads the state
/// for the coach message and the word to trace; progress itself lives in the
/// game session's found set (the single source of truth), so a player who
/// traces a different valid answer than the prompted one still gets credit
/// when that answer happens to be a tutorial target.
class TutorialController extends Notifier<TutorialState?> {
  /// Blocks restarts within this app run once the player finished or skipped.
  /// Persistence (tutorialSeen) covers the next run.
  bool _dismissed = false;

  @override
  TutorialState? build() {
    // Listeners re-read current values via ref.read so a stale captured
    // snapshot can never start or advance the tutorial.
    ref.listen(settingsProvider, (prev, next) => _maybeStart());
    ref.listen(gameSessionProvider, (prev, next) {
      _maybeStart();
      _onSessionChanged();
    });
    // Both dependencies may already hold values when this notifier first
    // builds (the settings stream is keep-alive, so an earlier settings-page
    // visit starts it); in that case neither listener ever fires. Run one
    // check right after build so that path still starts the tutorial.
    Future.microtask(() {
      if (ref.mounted) _maybeStart();
    });
    return null;
  }

  /// Starts the tutorial for the current session when a fresh install first
  /// reaches an untouched game. Targets are the first two answers in the
  /// session's shortest-first target order (one if the puzzle has a single
  /// answer).
  void _maybeStart() {
    if (_dismissed || state != null) return;
    final settings = ref.read(settingsProvider).value;
    if (settings == null || settings.tutorialSeen) return;
    final session = ref.read(gameSessionProvider);
    if (session == null || session.found.isNotEmpty) return;
    final words = [
      for (final answer in session.targets.take(2)) answer.word.toUpperCase(),
    ];
    if (words.isEmpty) return;
    state = TutorialState(
      targetWords: words,
      stepIndex: 0,
      phase: TutorialPhase.trace,
    );
  }

  /// Advances the trace as the session's found set grows: step to the first
  /// target not yet found, or celebrate when every target is in.
  void _onSessionChanged() {
    final tutorial = state;
    if (tutorial == null || tutorial.phase != TutorialPhase.trace) return;
    final session = ref.read(gameSessionProvider);
    if (session == null) return;
    final next =
        tutorial.targetWords.indexWhere((w) => !session.found.contains(w));
    if (next == -1) {
      _finish();
    } else if (next != tutorial.stepIndex) {
      state = tutorial.copyWith(stepIndex: next);
    }
  }

  /// Player tapped Skip: hide immediately and never show again.
  void skip() {
    _dismissed = true;
    state = null;
    unawaited(_markSeen());
  }

  /// Called by the UI after the celebrate pill has been shown; seen was
  /// already persisted by [_finish].
  void dismissCelebration() {
    _dismissed = true;
    state = null;
  }

  /// All targets found: celebrate and persist seen. The UI dismisses the
  /// celebration via [dismissCelebration] once the pill has had its moment.
  void _finish() {
    final tutorial = state;
    if (tutorial == null) return;
    state = tutorial.copyWith(phase: TutorialPhase.celebrate);
    unawaited(_markSeen());
  }

  /// The single persistence seam: the tutorial is a one-time, local-only
  /// affordance, so it writes straight to the settings DAO.
  Future<void> _markSeen() =>
      ref.read(settingsDaoProvider).setTutorialSeen(true);
}

final tutorialProvider = NotifierProvider<TutorialController, TutorialState?>(
  TutorialController.new,
);
