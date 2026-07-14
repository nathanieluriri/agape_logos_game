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
/// Offense only: those are the four the server implements
/// (`match_powerup_service.ts`). Defense and utility items are purchasable but
/// have no gameplay hook yet, so they are deliberately absent - a null here means
/// "not firable in a match", which is exactly how the bar filters them out.
const Map<String, String> kPowerupWireKinds = <String, String>{
  'freeze_letter': 'letter_freeze',
  'fog': 'fog_bank',
  'scramble': 'scramble',
  'word_steal': 'word_steal',
};

/// The wire kind for [itemId], or null when the item cannot be fired in a match.
String? powerupWireKind(String itemId) => kPowerupWireKinds[itemId];
