/// Refill the local cache when unplayed puzzles drop below this count.
const int kRefillThreshold = 20;

/// Per-tier composition requested from POST /puzzles/draw. Frontend-chosen.
const Map<String, int> kDrawComposition = {'easy': 20, 'medium': 40, 'hard': 40};

/// Mutation kind for puzzle-result writes; the reconciler keys off this.
const String kPuzzleResultKind = 'puzzle_result';
