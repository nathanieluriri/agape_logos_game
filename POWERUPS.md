# Powerups - icon spec

Everything the player can buy and use, with the SVG each one needs. Source of truth for
the data itself is `functions/src/store/catalog.ts` (server) - this file exists so the
icons can be drawn without reading the backend.

## Where the files go

```
assets/powerups/          <- NEW folder, create it
  hint.svg
  freeze_letter.svg
  fog.svg
  scramble.svg
  word_steal.svg
  shield.svg
  combo_lock.svg
  time_boost.svg
  double_points.svg
  hint_pack.svg           (bundle)
  skirmish_pack.svg       (bundle)
```

**Filename = the item's `id`, exactly.** That is not cosmetic: the app resolves an icon as
`assets/powerups/<id>.svg`, so a typo means a missing icon rather than a broken build. The
ids are fixed by the server and the player's inventory keys, so do not rename them.

Once the folder exists it must be declared in `pubspec.yaml` under `flutter: assets:` as
`- assets/powerups/` (alongside `assets/branding/`). I will wire that up.

## Drawing notes

- **Square viewBox** (`0 0 24 24` or `0 0 48 48`), centered, with a little padding so the
  glyph does not touch the edge.
- Rendered small: **22-28px** in the match powerup bar, ~32px in the store. Keep them
  legible at 22px - no hairlines, no fine text.
- They sit on the pond palette (deep teal / green pads). The existing `assets/branding/`
  SVGs are the reference for weight and feel.
- Ship them **monochrome or two-tone** if you can. A flat single-color glyph can be tinted
  by the app for its enabled / disabled / cooldown states; a full-color SVG cannot, and
  will look wrong when a powerup is locked or spent.
- Offense vs defense reads best if the silhouettes differ: offense pointed / directional,
  defense round / enclosing.

## The powerups

### Offense (fired AT your opponent, live in a match)

These four are the ones that appear in the match powerup bar.

| Icon file | Name | What it does | Cost |
|---|---|---|---|
| `freeze_letter.svg` | **Letter Freeze** | Locks one of the opponent's rack letters so they cannot use it for 10s. | 120 |
| `fog.svg` | **Fog Bank** | Blurs the opponent's board for 8s. | 100 |
| `scramble.svg` | **Scramble** | Shuffles the opponent's rack once, breaking their setup. | 90 |
| `word_steal.svg` | **Word Steal** | Steals one word the opponent has found, taking its points. | 260 |

Suggested imagery: a frozen / iced letter tile; a rolling fog bank or cloud over a board;
two arrows swapping (distinct from the in-game shuffle button); a hand or hook lifting a
word tile away.

### Defense (protects you)

| Icon file | Name | What it does | Cost |
|---|---|---|---|
| `shield.svg` | **Bubble Shield** | Nullifies the next powerup used against you. | 150 |
| `combo_lock.svg` | **Combo Lock** | Your combo does not reset on your next wrong word. | 110 |

Suggested imagery: a soap / water bubble (pond-native, not a knight's shield); a padlock
fused with a combo flame or chevron.

### Utility (helps you)

| Icon file | Name | What it does | Cost |
|---|---|---|---|
| `time_boost.svg` | **Time Boost** | Adds 15s to your own clock. | 80 |
| `double_points.svg` | **Double Points** | Your next valid word scores double. | 140 |

Suggested imagery: a clock / hourglass with a plus; a bold "x2" or a doubled petal.

### Hint

| Icon file | Name | What it does | Cost |
|---|---|---|---|
| `hint.svg` | **Hint** | Reveals the next letter of an unsolved word. | 50 |

Suggested imagery: a lotus bud opening, or a lantern. Avoid the generic lightbulb if you
can - it fights the pond theme.

### Bundles (store only, never in the match bar)

Bundles grant base items rather than being usable themselves, so their icons only ever
appear on a store card.

| Icon file | Name | Grants | Cost |
|---|---|---|---|
| `hint_pack.svg` | **Hint Pack** | 5x Hint | 200 |
| `skirmish_pack.svg` | **Skirmish Pack** | 2x Letter Freeze, 2x Fog Bank, 1x Bubble Shield | 500 |

Suggested imagery: a stack / bundle of the base glyph. If these are a pain to draw, the app
can fall back to the primary granted item's icon with a "pack" badge - say the word and I
will do that instead, and you can skip these two.

## Status: defense and utility are not wired up yet

Only the four **offense** powerups have a server implementation
(`functions/src/services/match_powerup_service.ts` handles exactly
`letter_freeze | fog_bank | scramble | word_steal`). **Bubble Shield, Combo Lock, Time
Boost and Double Points are purchasable but do nothing** - the catalog calls the metadata
"forward-looking". Their icons are still worth drawing (they show in the store), but the
gameplay hooks are a separate piece of work.
