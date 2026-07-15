/// Maps a store item id to the wire `kind` the powerup endpoint accepts.
///
/// These are two different vocabularies and they do NOT match:
///   store item id  ->  wire kind
///   freeze_letter  ->  letter_freeze     (the words are swapped)
///   fog            ->  fog_bank
///
/// The match bar used to send `item.effect.rule` as the kind, but `rule` is
/// human rules text ("Disable 1 opponent letter for 10s."), not an enum. The
/// server validates `kind` against a zod enum, so every fire was rejected with a
/// 400 and no powerup could ever be used. Keep this map as the single crossing
/// point between the two vocabularies.
///
/// Offense (letter_freeze, fog_bank, scramble, word_steal) targets the
/// opponent; the rest are defense/self-target effects the caster applies to
/// themselves (shield, time_boost, double_points, combo_lock).
const Map<String, String> kPowerupWireKinds = <String, String>{
  'freeze_letter': 'letter_freeze',
  'fog': 'fog_bank',
  'scramble': 'scramble',
  'word_steal': 'word_steal',
  'shield': 'shield',
  'time_boost': 'time_boost',
  'double_points': 'double_points',
  'combo_lock': 'combo_lock',
};

/// The four kinds that target the opponent. Every other firable kind is
/// defense/self-target (armed on, or applied to, the caster).
const Set<String> kOffensiveWireKinds = <String>{
  'letter_freeze',
  'fog_bank',
  'scramble',
  'word_steal',
};

/// The wire kind for [itemId], or null when the item cannot be fired in a match.
String? powerupWireKind(String itemId) => kPowerupWireKinds[itemId];

/// True when [itemId] targets the opponent rather than the caster.
bool isOffensive(String itemId) {
  final wireKind = kPowerupWireKinds[itemId];
  return wireKind != null && kOffensiveWireKinds.contains(wireKind);
}
