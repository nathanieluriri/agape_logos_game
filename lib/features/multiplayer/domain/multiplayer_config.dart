/// Reduced, unambiguous join-code alphabet shared with the backend
/// (contract 8.6): no I/O/Q/X/Z, so codes never get misread and the set is
/// small enough to render on a LetterWheel. The client always uppercases.
const String kMatchCodeAlphabet = 'ABCDEFGHJKLMNPRSTUVWY';

/// Join-code length (contract 8.6).
const int kMatchCodeLength = 4;

/// Whether the theme/synonym system (built from scratch in plan 11, section 6)
/// is live. While false the match-settings theme picker is HIDDEN and matches
/// draw untethered words (`settings.theme = null`). Flip to true once plan 11
/// ships `GET /themes` with a non-empty list.
const bool kThemeSystemEnabled = false;

/// Mutation `kind` for a durably-queued match forfeit (`POST /matches/:id/leave`).
/// The sync engine replays it with backoff, and the optional reconciler keys off
/// this to refresh the Resume list / badge / history once the server finalizes.
const String kMatchLeaveKind = 'match_leave';
