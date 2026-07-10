/// Refill the local cache when unplayed puzzles drop below this count.
const int kRefillThreshold = 20;

/// Per-tier composition requested from POST /puzzles/draw. Frontend-chosen.
const Map<String, int> kDrawComposition = {'easy': 20, 'medium': 40, 'hard': 40};

/// Smaller first-login draw so the first puzzle appears quickly; the full
/// composition tops the cache up in the background afterwards.
const Map<String, int> kFirstDrawComposition = {'easy': 8, 'medium': 4, 'hard': 0};

/// Mutation kind for puzzle-result writes; the reconciler keys off this.
const String kPuzzleResultKind = 'puzzle_result';

/// Puzzle-id prefix of the bundled offline starter pack. Results for these
/// are recorded locally only (never enqueued for backend sync).
const String kStarterPuzzlePrefix = 'starter-';

/// Fewest defined answers a puzzle may keep and still be playable. Words with
/// no definition are dropped at the read seam (every surfaced word must carry a
/// definition); a puzzle left with fewer than this is skipped entirely.
const int kMinPlayableAnswers = 2;
