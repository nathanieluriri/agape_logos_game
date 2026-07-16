/// Result of a `POST /store/purchase`. The wallet is server-owned, so a purchase
/// is an online, server-authoritative write (not an optimistic-queue write):
/// the server is the only place that can atomically debit coins and grant items,
/// and every call carries an idempotency key so a retry never double-charges.
sealed class PurchaseOutcome {
  const PurchaseOutcome();
}

/// The purchase (or an idempotent replay of it) succeeded. [coins] and
/// [inventory] are the authoritative post-purchase values from the server.
class PurchaseSuccess extends PurchaseOutcome {
  const PurchaseSuccess({
    required this.coins,
    required this.inventory,
    required this.charged,
    required this.replay,
  });

  final int coins;
  final Map<String, int> inventory;
  final int charged;

  /// True when the server had already applied this idempotency key (a replay),
  /// so no fresh charge was made.
  final bool replay;
}

/// The wallet was short. Carries the server's view of the [cost] and current
/// [coins] so the UI can explain the gap.
class PurchaseInsufficientCoins extends PurchaseOutcome {
  const PurchaseInsufficientCoins({required this.cost, required this.coins});

  final int cost;
  final int coins;
}

/// The wallet was short on the server, but winnings that cover (or shrink) the
/// gap are still travelling in the offline queue, so the balance on screen is
/// ahead of the server's. Nothing was charged. The caller should explain that
/// the petals are still syncing and invite a retry in a moment, rather than
/// telling the player they can't afford something they can see they can.
class PurchaseCoinsSyncing extends PurchaseOutcome {
  const PurchaseCoinsSyncing({required this.cost, required this.coins});

  /// The server's view of the item cost and wallet at the time of the attempt.
  final int cost;
  final int coins;
}

/// The item id was rejected by the server (unknown / delisted).
class PurchaseUnknownItem extends PurchaseOutcome {
  const PurchaseUnknownItem();
}

/// The request could not reach the server (offline or a transient/network
/// error). Nothing was charged; the caller should invite a retry.
class PurchaseUnavailable extends PurchaseOutcome {
  const PurchaseUnavailable();
}
