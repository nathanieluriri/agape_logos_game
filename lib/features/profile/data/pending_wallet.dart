import 'dart:convert';

import '../../../core/logging/app_logger.dart';
import '../../../core/storage/app_database.dart';
import '../../puzzles/puzzles_config.dart';

/// Petals the player has earned locally that the server has not minted yet:
/// the sum of the mint formula over every puzzle-result mutation still waiting
/// in the offline queue.
///
/// This is the reconciliation seam that keeps the wallet stable. Every server
/// write-through (a `GET /me` merge, a `GET /me/coins`, a purchase response)
/// adds this delta on top of the server balance before writing the cached row,
/// so a server value that has not yet seen the queued winnings can never
/// clobber the optimistic balance the player is looking at. Once a queued
/// result syncs, it leaves the queue (delta shrinks) at the same time the
/// server balance grows, so the displayed total stays put.
///
/// TOCTOU note: the delta is read at a different moment than the server
/// snapshot it gets added to, so a row can sync (or be enqueued) in between,
/// briefly double- or under-counting one result. This is tolerated by design:
/// the reconciler's post-sync refetch recomputes `server + delta` from fresh
/// values and self-heals the cached balance within moments.
Future<int> pendingCoinDelta(AppDatabase db) async {
  final rows = await db.pendingMutationsDao.unsynced(const [kPuzzleResultKind]);
  var delta = 0;
  for (final row in rows) {
    delta += _mintedCoins(row.payloadJson);
  }
  return delta;
}

/// Coins the server will mint for one queued puzzle-result payload. Defensive:
/// a malformed payload contributes 0 rather than corrupting the balance.
int _mintedCoins(String payloadJson) {
  try {
    final decoded = jsonDecode(payloadJson);
    if (decoded is! Map<String, dynamic>) return 0;
    final score = (decoded['score'] as num?)?.toInt();
    return score == null ? 0 : coinsForScore(score);
  } catch (e) {
    logger.warning('unreadable pending puzzle-result payload: $e');
    return 0;
  }
}
