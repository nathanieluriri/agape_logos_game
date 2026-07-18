/// Centralized SFX filenames (`assets/audio/...`), the single source of truth
/// so a key is never typo'd at a call site. Callers pass these straight to
/// `AudioService.playSfx`.
///
/// No audio assets ship with the app yet (`assets/audio/` is empty and not
/// declared in `pubspec.yaml`): these keys are wired through the multiplayer
/// powerup animations and core match moments (word found, match won/lost,
/// opponent scored) now so the call sites are sound-ready, but
/// `_playSfxQuiet` (match_page.dart) swallows the resulting failure instead of
/// crashing the match until real files land at these paths.
abstract final class SfxKeys {
  const SfxKeys._();

  /// The caster fires a powerup (cast flyout starts).
  static const String powerupCast = 'powerup_cast.mp3';

  /// An incoming powerup banner appears for the target.
  static const String powerupIncoming = 'powerup_incoming.mp3';

  /// A shield absorbs an offensive powerup (both the caster's "Blocked!" and
  /// the victim's "Shield blocked ...!" share this cue), or a ward refuses
  /// one outright ("Warded!").
  static const String powerupBlocked = 'powerup_blocked.mp3';

  /// I just found a word (a new local entry landed in the rack).
  static const String wordFound = 'word_found.mp3';

  /// The match just finished and I won.
  static const String matchWon = 'match_won.mp3';

  /// The match just finished and I lost.
  static const String matchLost = 'match_lost.mp3';

  /// The opponent's `wordsFound` just went up.
  static const String opponentScored = 'opponent_scored.mp3';
}
