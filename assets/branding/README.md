# Branding assets

## App launcher icon: `app_icon.png`

The launcher icon is generated from a single source PNG.

1. Save the icon art (the glass-orb lotus mark) here as **`app_icon.png`**, a
   square **RGBA** PNG, ideally **1024x1024**. The art is transparent-backed (the
   lotus disc floats on a transparent field), which is what lets the adaptive
   background color show through behind the whole mark.
2. From the project root run:

   ```
   dart run flutter_launcher_icons
   ```

   (Config lives under `flutter_launcher_icons:` at the bottom of `pubspec.yaml`.)

This regenerates:

- every Android mipmap density (`android/app/src/main/res/mipmap-*/`)
- the Android **adaptive** icon (transparent foreground + `#0C7F80` teal-green background, `AppColors.pond3`)
- the web icons and favicon (`web/icons/`, `web/favicon.png`)

The Android launch screen references `@mipmap/ic_launcher`, so it updates to match automatically.
The in-app Flutter splash still paints cream (`AppColors.paper`); see plan 03 OPTIONAL Task 6 if
you want it to match the pond green too.

### Optional: a crisper adaptive icon

Android masks adaptive icons to a circle or squircle and zooms the foreground
slightly. The round orb survives this well, but for a perfect fit you can export
a **padded, transparent** foreground (the orb centred at roughly 70% with a
transparent margin) as `app_icon_foreground.png`, then point
`adaptive_icon_foreground` at it in `pubspec.yaml` before regenerating.

## Existing marks

- `lotus.svg` - the seven-petal lotus wordmark flower.
- `coin_petal.svg` / `coin_petal.png` - the coin petal.
- `google_g.svg` - Google sign-in glyph.

The in-app splash does not need any PNG: it is drawn from vector geometry in
`lib/core/design/brand_mark_geometry.dart` and `lib/shared/widgets/brand_mark.dart`.
