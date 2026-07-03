/// Result of a claim (`POST /rewards/claim-coins` or `/rewards/claim-powerup`).
/// Claims are `OnlineOnly`: the server enforces the cooldown, so there is no
/// optimistic path (an optimistic claim could grant a reward the server later
/// rejects). The cooldown itself is the dedup, so a claim needs no idempotency
/// key.
sealed class ClaimResult {
  const ClaimResult();
}

/// The 72h coin reward was granted. [coins] is the authoritative new balance.
class ClaimCoinsSuccess extends ClaimResult {
  const ClaimCoinsSuccess({
    required this.claimed,
    required this.coins,
    required this.nextClaimInMs,
  });

  final int claimed;
  final int coins;
  final int nextClaimInMs;
}

/// The weekly powerup was granted. [granted] is the base item id; [inventory] is
/// the authoritative post-claim inventory.
class ClaimPowerupSuccess extends ClaimResult {
  const ClaimPowerupSuccess({
    required this.granted,
    required this.inventory,
    required this.nextClaimInMs,
  });

  final String granted;
  final Map<String, int> inventory;
  final int nextClaimInMs;
}

/// Rewards are still locked (player below [minLevel]).
class ClaimLocked extends ClaimResult {
  const ClaimLocked({required this.minLevel});

  final int minLevel;
}

/// Already claimed; the next claim opens in [nextClaimInMs].
class ClaimOnCooldown extends ClaimResult {
  const ClaimOnCooldown({required this.nextClaimInMs});

  final int nextClaimInMs;
}

/// Could not reach the server (offline or transient). Nothing was granted.
class ClaimUnavailable extends ClaimResult {
  const ClaimUnavailable();
}
