# CLAUDE.md - agape_logos_game

Guidance for Claude Code (and humans) working in this repository. A Flutter **Flame**
Zen word game: offline-first, optimistic, **Android + Web only** (no iOS/desktop).

---

## ⛔ Git, commits & attribution - HARD RULES (never violate)

- **NEVER add co-authoring or AI attribution to commits or PRs.** Absolute.
- No `Co-Authored-By:` trailers. No "Generated with Claude Code" footers. Commit/PR text
  is human-authored change content only.
- Enforced via `.claude/settings.json` (`includeCoAuthoredBy: false`, `attribution.commit`/`pr` = `""`).
- `docs/` is **gitignored** (design specs/plans live there locally).

## ✍️ Writing style - HARD RULE (never violate)

- **Never use em dashes** (the long dash, Unicode U+2014) anywhere: prose, code comments,
  commit messages, docs, social copy, and generated graphics. Use commas, colons,
  parentheses, or periods instead. A plain hyphen ("-") is fine for compound words.

## Environment & toolchain gotchas (read before building)

- **Flutter SDK lives at `C:\flutter`** (relocated from `C:\Users\Mr Dashi\flutter`).
  Spaces in the SDK path break the Dart **native-assets** build (sqlite3's hook invokes
  an unquoted dart path → `'C:\Users\Mr' is not recognized`). If bare `flutter` resolves
  to the old spaces path, use `C:\flutter\bin\flutter`. The old SDK copy can be deleted
  once the IDE is closed; the Machine PATH entry is stale (harmless) until updated (admin).
- **Native assets must stay ENABLED** (`flutter config --enable-native-assets`) - `sqlite3 3.x`
  (via Drift) requires it. Do not disable.
- **NDK pinned to `27.0.12077973`** in `android/app/build.gradle.kts` (Flutter's default
  `28.2.13676358` was a corrupt partial install). The `jni` plugin warns it wants 28.2,
  but 27 builds fine (NDKs are backward-compatible). Revert to `flutter.ndkVersion` only
  after a clean 28.2 install.
- **Versions:** Flutter 3.44.2 / Dart 3.12 · Riverpod **3.x** · freezed **3.x**
  (`@freezed abstract class X with _$X`) · drift 2.34 · go_router 17. `riverpod_lint` is
  intentionally **omitted** (analyzer-version conflict with the current set; revisit later).

## Mandatory dev workflow (run after ANY change, fix until clean/green)

1. `dart run build_runner build` - regenerate after touching Drift tables/DAOs, freezed
   models, or json. Generated `*.g.dart` / `*.freezed.dart` **are committed**.
2. `flutter analyze` - must be **clean** (No issues found).
3. `flutter test` - must **pass**.
4. `flutter build apk --release --no-tree-shake-icons` - must **succeed** (primary gate).
   The flag ships the full MaterialIcons font (~1.6MB): Shorebird patches cannot add
   glyphs to the release APK's tree-shaken font subset, so any `Icons.*` reference added
   after a release renders blank on patched installs without it. Use the same flag on
   `shorebird release` / `shorebird patch`. New UI glyphs should prefer the hand-painted
   `PondIcon`/`PondGlyph` family (`lib/shared/widgets/glyphs/`), which has no font
   dependency at all.

## Plan execution (workflow preference - never violate)

- When executing an implementation plan, **ALWAYS use subagent-driven development**
  (`superpowers:subagent-driven-development`): one fresh implementer subagent per task, a
  task review after each, and a whole-branch review at the end. Proceed automatically; do
  **not** ask for confirmation of the execution mode.

## Architecture (feature-first, clean-ish layering)

```
lib/
  main.dart                 # thin: await bootstrap()
  app/                      # bootstrap, root MaterialApp.router, router + animated transitions
  core/
    design/{tokens,theme,motion}   # DESIGN TOKENS - single source of truth
    platform/                       # platform abstraction (conditional imports)
    network/ connectivity/ offline/ storage/ error/ audio/ logging/ utils/
  features/<feature>/{domain,data,application,presentation/{pages,widgets}}
  shared/widgets/           # reusable cross-feature widgets
  game/                     # Flame game/components/systems
  preview/                  # @Preview design harness (flutter widget-preview start)
```

### Separation & composition rules (mandatory)
- **Design tokens are separated and authoritative.** No raw `Color(...)`, magic numbers,
  or ad-hoc `Duration`s in widgets - reference `AppColors`/`AppSpacing`/`AppRadii`/
  `AppDurations`/`AppCurves` (or the `ThemeData` from `AppTheme`).
- **Widgets are separated, small, single-purpose, and `const` wherever possible.**
- **Pages are thin compositions of widgets** with no business logic. If a page grows past
  a screenful, split it into composed sub-widgets.
- **Use OOP for shared behavior:** abstract interfaces (`AudioService`,
  `LevelResultRepository`, `SyncScheduler`), base classes/mixins (`OfflineAwareRepository`),
  abstraction over data sources. Keep files focused (~≤250 lines).

## Offline / optimistic engine (the core)

Three **call policies** (`core/offline/call_policy.dart`) - pick one per repository call:
1. `OnlineOnly` - pure reads; connectivity-gated; never fires while offline.
2. `CachedRead` - fetch online + write-through to Drift; serve cache offline.
3. `OptimisticWrite` - apply to local Drift **immediately** (UI source of truth) → enqueue
   a mutation → `SyncEngine` flushes when reachable (single-flight, exponential backoff,
   idempotency key). On success: mark synced + run the `kind`-keyed reconciler. On
   permanent failure: mark failed.
- **"Don't call when offline" lives in one place:** `ConnectivityService` (real
  reachability) + the Dio `ConnectivityInterceptor`.
- **Reconciliation seam:** `SyncEngine` never imports features; it calls `MutationReconciler`s
  keyed by `mutation.kind`. Features register handlers via `mutationReconcilersProvider`.

## Platform split (Android vs Web)

- One interface, two impls selected by **conditional import** - never branch capabilities
  on `kIsWeb` in features. `kIsWeb` is allowed only for trivial local UI tweaks.
- `SyncScheduler`: Android = WorkManager background flush + foreground safety net; Web =
  foreground (connectivity + resume) only. Factory in `sync_scheduler_factory.dart`.
- Drift connection: `storage/connection/` splits native (`sqlite3_flutter_libs`) vs web
  (WASM - needs `sqlite3.wasm` + `drift_worker.js` in `web/`).

## Jank / performance rules

- `const` everywhere (lint-enforced); granular Riverpod providers + `ref.watch(p.select(...))`;
  no logic in `build()`.
- `RepaintBoundary` around the Flame canvas and animated layers; avoid `Opacity`/`ClipPath`
  in hot paths (prefer `AnimatedOpacity`).
- Heavy JSON decode off the main isolate (`Isolate.run`/`compute`); Drift runs off-thread.
- Preload audio + key images at bootstrap. Profile with `--profile` + DevTools overlay.

## Animation & sound conventions

- Every screen transition uses the shared animated page builder
  (`app/router/transitions.dart`) with motion **tokens** - navigation is always game-like.
- Navigating buttons are animated actions (feedback + transition + optional SFX) via a
  shared widget.
- Audio behind `AudioService` (`flame_audio` impl); SFX keys centralized; respect global mute.

## Web build gotcha: the stale plugin registrant (silently kills Firestore)

`flutter build web` reuses a generated `web_plugin_registrant.dart` under
`.dart_tool/flutter_build/<hash>/`, and it does **not** always regenerate when a plugin is
added. A copy that predates `cloud_firestore` omits `FirebaseFirestoreWeb.registerWith`,
so `FirebaseFirestore.instance` silently falls back to the Android **method-channel**
implementation. On web that dies inside the Pigeon codec with
`Unsupported operation: Int64 accessor not supported by dart2js` (JS has no 64-bit ints),
which `runZonedGuarded` swallows: no listener ever opens, no error reaches the UI, and
every Firestore-backed screen (all of multiplayer) just spins forever. `flutter run`
uses a different, correct registrant, so **this reproduces only in a release build**.

- Symptom to recognize: `firebase-firestore*.js` is never fetched and there is zero
  `firestore.googleapis.com` traffic, while auth and the HTTP API work fine.
- Fix / prevention: `flutter clean` before `flutter build web --release`. Verify with
  `grep -ci firestore .dart_tool/flutter_build/*/web_plugin_registrant.dart` (must be > 0).

## Current state (playable core loop)

The game is live end to end on Android: Play gates on Firebase auth (email, Google, or
guest via `startPlayFlow`), puzzles are drawn from the deployed Cloud Function
(`kApiBaseUrl` in `core/network/api_config.dart`) and cached in Drift, gameplay runs the
letter wheel + word board + hints/shuffle/combo, `commitWin` records the result through
the optimistic queue, and the level-complete screen advances to the next puzzle.
`kBackendSyncEnabled = true`: foreground and WorkManager background flush both use the
real `HttpMutationSender`. Double-send safety ultimately rests on the per-mutation
**idempotency key** (at-least-once delivery); single-flight + the `inFlight` claim just
minimize duplicates.

- **Offline first run:** when the cache is empty and the backend is unreachable,
  `PuzzleRepositoryImpl` seeds the bundled pack `assets/puzzles/starter_pack.json`
  (seam: `PuzzleSeedSource`). Starter results (`kStarterPuzzlePrefix` ids) complete
  locally and **skip the sync queue**. If truly nothing is playable, the game page shows
  `EmptyPondNotice` (retry), never an endless spinner.
- **Store + daily rewards are live:** the wallet "+" opens `/store` (feature at
  `features/store/`), which reads the backend catalog (`GET /store`) and inventory
  (`GET /me/inventory`) and spends coins via `POST /store/purchase`. Because the wallet
  is server-owned, a purchase is an online, server-authoritative write (carrying an
  idempotency-key header), not an optimistic-queue write; the returned balance is written
  through to the cached profile so the coin pill updates at once. The Home screen shows a
  `RewardTimerPad` (`features/rewards/`) reading `GET /rewards`: a live 72h countdown that
  becomes a Claim button (`POST /rewards/claim-coins`, 400 coins), plus the weekly powerup
  claim when ready. Rewards unlock at level 5 (server `REWARD_MIN_LEVEL`). Both features
  use plain models (no Drift tables, no generated code), so build_runner is not required
  for them.
- **Still stubbed:** Withdraw, Bonus Gift (coming-soon sheets). Dictionary now
  opens the session dictionary sheet (found words show definitions, unfound stay masked).
  `level_results` remains the original optimistic-path sample.
- **Auth caveat:** guest sign-in needs network the first time, so a never-online fresh
  install cannot reach gameplay yet (product decision pending).

## Pond design system & widget previews

- **Pad silhouette single source of truth:** `core/design/pad_geometry.dart`
  (`PadGeometry.notchedPad`/`smoothPad`/`veins`, 100x100 viewBox). Used by the
  `LilyPad` painter (shared/widgets) and the ambient `PadShadowComponent` (Flame).
  The base is a softly rounded three-sided shape (not a circle); the play pad adds two
  rim nicks that never reach the center.
- **Pad depth layers (painter order):** blurred cast shadow → hard darker `underside`
  offset → radial sheen fill → vein texture → light rim glow along the top edge. All
  colors/gradients are tokens (`LilyPadPalette`, `AppGradients.padRimGlow`).
- **Design previews:** `lib/preview/pond_previews.dart` holds `@Preview` functions
  (screens, pads, top bar, progress bar). Run `flutter widget-preview start` (or the IDE
  panel). The previewer is Flutter Web: preview files must stay provider-free and must
  not import bootstrap, Drift, or Flame.

## Known follow-ups (not blocking)

- **Web runtime:** run `tool/fetch_web_runtime.ps1` once to download `sqlite3.wasm` +
  `drift_worker.js` (pinned to pubspec.lock: drift 2.34.0, sqlite3 3.3.3) into `web/`,
  or web Drift 404s at first DB use. APK/tests are unaffected.
- **Env cleanup:** delete the old SDK copy at `C:\Users\Mr Dashi\flutter` (when the IDE is
  closed) and point the **Machine PATH** at `C:\flutter\bin` (needs admin) so bare
  `flutter` uses the space-free SDK everywhere.
- **NDK:** reinstall a clean `28.2.13676358` and revert `ndkVersion` to `flutter.ndkVersion`.
- **riverpod_lint:** re-add once it supports the current analyzer.

## Build-in-public posts (in `post/day N/`, gitignored)

Every post is a **set of three square (1080x1080) images** in the paper / sage / gold token
palette, plus `social.md` and `medium.md` copy:

1. **Diagram:** the planning phase and the actual execution. A soft logic / flow tree of how
   the system works.
2. **Graphic:** the summary / trailer. Good-looking, a little bit of code, a **progress
   bar/ring**, and a few key numbers.
3. **Slide:** the narrative. A **famous quote** related to the work, the day's **breaks and
   fixes**, and a general **overview of progress**.

Keep the look consistent across days (logo `n.png` mark, `anagram_light.png` signature).
