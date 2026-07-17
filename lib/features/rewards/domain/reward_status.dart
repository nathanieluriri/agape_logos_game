/// Snapshot of the caller's claim eligibility (`GET /rewards`). All eligibility
/// is computed server-side from stored timestamps, so this is a pure read the
/// home screen can poll freely. Mirrors the backend `RewardStatus`
/// (functions/src/services/rewards_service.ts).
class RewardStatus {
  const RewardStatus({
    required this.unlocked,
    required this.minLevel,
    required this.level,
    required this.coins,
    required this.powerup,
  });

  /// True once the player has reached [minLevel]; rewards are locked before it.
  final bool unlocked;
  final int minLevel;
  final int level;

  final CoinReward coins;
  final PowerupReward powerup;

  factory RewardStatus.fromJson(Map<String, dynamic> json) {
    final coins = json['coins'] as Map<String, dynamic>? ?? const {};
    final powerup = json['powerup'] as Map<String, dynamic>? ?? const {};
    return RewardStatus(
      unlocked: json['unlocked'] as bool? ?? false,
      minLevel: (json['minLevel'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 0,
      coins: CoinReward.fromJson(coins),
      powerup: PowerupReward.fromJson(powerup),
    );
  }
}

/// The recurring coin gift (400 coins every 72h on the current backend).
class CoinReward {
  const CoinReward({
    required this.amount,
    required this.claimable,
    required this.nextClaimInMs,
  });

  final int amount;
  final bool claimable;

  /// Milliseconds until the next claim opens; 0 when claimable now.
  final int nextClaimInMs;

  factory CoinReward.fromJson(Map<String, dynamic> json) => CoinReward(
    amount: (json['amount'] as num?)?.toInt() ?? 0,
    claimable: json['claimable'] as bool? ?? false,
    nextClaimInMs: (json['nextClaimInMs'] as num?)?.toInt() ?? 0,
  );
}

/// The weekly free powerup (a shuffle-bag draw).
class PowerupReward {
  const PowerupReward({required this.claimable, required this.nextClaimInMs});

  final bool claimable;
  final int nextClaimInMs;

  factory PowerupReward.fromJson(Map<String, dynamic> json) => PowerupReward(
    claimable: json['claimable'] as bool? ?? false,
    nextClaimInMs: (json['nextClaimInMs'] as num?)?.toInt() ?? 0,
  );
}
