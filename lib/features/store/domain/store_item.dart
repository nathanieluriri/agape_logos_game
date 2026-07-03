/// A single buyable entry from the backend catalog (`GET /store`). Plain and
/// immutable (no code generation) so it stays dependency-light; mirrors the
/// server `StoreItemSchema` (functions/src/schemas/store.ts).
///
/// Base items grant one of themselves; bundles carry [grants] and hand out base
/// consumables instead. Powerups carry forward-looking [effect] metadata the
/// eventual multiplayer mode will read; the store only needs name/cost/owned.
class StoreItem {
  const StoreItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.kind,
    required this.cost,
    required this.maxPerPurchase,
    this.effect,
    this.grants,
  });

  final String id;
  final String name;
  final String description;

  /// "hint" or "powerup".
  final String category;

  /// "hint", "offense", "defense", or "utility".
  final String kind;

  /// Coins charged per unit purchased.
  final int cost;

  /// Server-enforced cap on quantity per single purchase.
  final int maxPerPurchase;

  /// Effect metadata (absent for the plain hint and for bundles).
  final PowerupEffect? effect;

  /// When set, buying this grants these base item quantities (bundles).
  final Map<String, int>? grants;

  /// True for multi-item bundles (a hint pack, a skirmish pack).
  bool get isBundle => grants != null && grants!.isNotEmpty;

  factory StoreItem.fromJson(Map<String, dynamic> json) {
    final Object? rawGrants = json['grants'];
    final Object? rawEffect = json['effect'];
    return StoreItem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String? ?? 'powerup',
      kind: json['kind'] as String? ?? 'utility',
      cost: (json['cost'] as num).toInt(),
      maxPerPurchase: (json['maxPerPurchase'] as num?)?.toInt() ?? 1,
      effect: rawEffect is Map<String, dynamic>
          ? PowerupEffect.fromJson(rawEffect)
          : null,
      grants: rawGrants is Map<String, dynamic>
          ? rawGrants.map((k, v) => MapEntry(k, (v as num).toInt()))
          : null,
    );
  }
}

/// Forward-looking gameplay metadata attached to powerups. Inert today; the
/// real-time multiplayer mode will read target/duration/magnitude.
class PowerupEffect {
  const PowerupEffect({
    required this.target,
    required this.durationSec,
    required this.rule,
    this.magnitude,
  });

  /// "self" or "opponent".
  final String target;
  final int durationSec;
  final String rule;
  final double? magnitude;

  factory PowerupEffect.fromJson(Map<String, dynamic> json) => PowerupEffect(
        target: json['target'] as String? ?? 'self',
        durationSec: (json['durationSec'] as num?)?.toInt() ?? 0,
        rule: json['rule'] as String? ?? '',
        magnitude: (json['magnitude'] as num?)?.toDouble(),
      );
}
