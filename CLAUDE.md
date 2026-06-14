# CLAUDE.md — agape_logos_game

Guidance for Claude Code (and humans) working in this repository. A Flutter **Flame**
Zen word game: offline-first, optimistic, **Android + Web only** (no iOS/desktop).

---

## ⛔ Git, commits & attribution — HARD RULES (never violate)

- **NEVER add co-authoring or AI attribution to commits or PRs.** Absolute.
- No `Co-Authored-By:` trailers. No "Generated with Claude Code" footers. Commit/PR text
  is human-authored change content only.
- Enforced via `.claude/settings.json` (`includeCoAuthoredBy: false`, `attribution.commit`/`pr` = `""`).
- `docs/` is **gitignored** (design specs/plans live there locally).

## Environment & toolchain gotchas (read before building)

- **Flutter SDK lives at `C:\flutter`** (relocated from `C:\Users\Mr Dashi\flutter`).
  Spaces in the SDK path break the Dart **native-assets** build (sqlite3's hook invokes
  an unquoted dart path → `'C:\Users\Mr' is not recognized`). If bare `flutter` resolves
  to the old spaces path, use `C:\flutter\bin\flutter`. The old SDK copy can be deleted
  once the IDE is closed; the Machine PATH entry is stale (harmless) until updated (admin).
- **Native assets must stay ENABLED** (`flutter config --enable-native-assets`) — `sqlite3 3.x`
  (via Drift) requires it. Do not disable.
- **NDK pinned to `27.0.12077973`** in `android/app/build.gradle.kts` (Flutter's default
  `28.2.13676358` was a corrupt partial install). The `jni` plugin warns it wants 28.2,
  but 27 builds fine (NDKs are backward-compatible). Revert to `flutter.ndkVersion` only
  after a clean 28.2 install.
- **Versions:** Flutter 3.44.2 / Dart 3.12 · Riverpod **3.x** · freezed **3.x**
  (`@freezed abstract class X with _$X`) · drift 2.34 · go_router 17. `riverpod_lint` is
  intentionally **omitted** (analyzer-version conflict with the current set; revisit later).

## Mandatory dev workflow (run after ANY change, fix until clean/green)

1. `dart run build_runner build` — regenerate after touching Drift tables/DAOs, freezed
   models, or json. Generated `*.g.dart` / `*.freezed.dart` **are committed**.
2. `flutter analyze` — must be **clean** (No issues found).
3. `flutter test` — must **pass**.
4. `flutter build apk --release` — must **succeed** (primary gate).

## Architecture (feature-first, clean-ish layering)

```
lib/
  main.dart                 # thin: await bootstrap()
  app/                      # bootstrap, root MaterialApp.router, router + animated transitions
  core/
    design/{tokens,theme,motion}   # DESIGN TOKENS — single source of truth
    platform/                       # platform abstraction (conditional imports)
    network/ connectivity/ offline/ storage/ error/ audio/ logging/ utils/
  features/<feature>/{domain,data,application,presentation/{pages,widgets}}
  shared/widgets/           # reusable cross-feature widgets
  game/                     # Flame game/components/systems
```

### Separation & composition rules (mandatory)
- **Design tokens are separated and authoritative.** No raw `Color(...)`, magic numbers,
  or ad-hoc `Duration`s in widgets — reference `AppColors`/`AppSpacing`/`AppRadii`/
  `AppDurations`/`AppCurves` (or the `ThemeData` from `AppTheme`).
- **Widgets are separated, small, single-purpose, and `const` wherever possible.**
- **Pages are thin compositions of widgets** with no business logic. If a page grows past
  a screenful, split it into composed sub-widgets.
- **Use OOP for shared behavior:** abstract interfaces (`AudioService`,
  `LevelResultRepository`, `SyncScheduler`), base classes/mixins (`OfflineAwareRepository`),
  abstraction over data sources. Keep files focused (~≤250 lines).

## Offline / optimistic engine (the core)

Three **call policies** (`core/offline/call_policy.dart`) — pick one per repository call:
1. `OnlineOnly` — pure reads; connectivity-gated; never fires while offline.
2. `CachedRead` — fetch online + write-through to Drift; serve cache offline.
3. `OptimisticWrite` — apply to local Drift **immediately** (UI source of truth) → enqueue
   a mutation → `SyncEngine` flushes when reachable (single-flight, exponential backoff,
   idempotency key). On success: mark synced + run the `kind`-keyed reconciler. On
   permanent failure: mark failed.
- **"Don't call when offline" lives in one place:** `ConnectivityService` (real
  reachability) + the Dio `ConnectivityInterceptor`.
- **Reconciliation seam:** `SyncEngine` never imports features; it calls `MutationReconciler`s
  keyed by `mutation.kind`. Features register handlers via `mutationReconcilersProvider`.

## Platform split (Android vs Web)

- One interface, two impls selected by **conditional import** — never branch capabilities
  on `kIsWeb` in features. `kIsWeb` is allowed only for trivial local UI tweaks.
- `SyncScheduler`: Android = WorkManager background flush + foreground safety net; Web =
  foreground (connectivity + resume) only. Factory in `sync_scheduler_factory.dart`.
- Drift connection: `storage/connection/` splits native (`sqlite3_flutter_libs`) vs web
  (WASM — needs `sqlite3.wasm` + `drift_worker.js` in `web/`).

## Jank / performance rules

- `const` everywhere (lint-enforced); granular Riverpod providers + `ref.watch(p.select(...))`;
  no logic in `build()`.
- `RepaintBoundary` around the Flame canvas and animated layers; avoid `Opacity`/`ClipPath`
  in hot paths (prefer `AnimatedOpacity`).
- Heavy JSON decode off the main isolate (`Isolate.run`/`compute`); Drift runs off-thread.
- Preload audio + key images at bootstrap. Profile with `--profile` + DevTools overlay.

## Animation & sound conventions

- Every screen transition uses the shared animated page builder
  (`app/router/transitions.dart`) with motion **tokens** — navigation is always game-like.
- Navigating buttons are animated actions (feedback + transition + optional SFX) via a
  shared widget.
- Audio behind `AudioService` (`flame_audio` impl); SFX keys centralized; respect global mute.

## Non-goals / don't do yet

No real screens, levels, game logic, API endpoints, theme aesthetics, or art. The
`level_results` feature is a deletable sample proving the optimistic path. Repositories/
endpoints are stubbed (the offline sender is a permanent no-op until a backend exists).
