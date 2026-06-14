# CLAUDE.md — agape_logos_game

Guidance for Claude Code (and humans) working in this repository.

> **Status:** Groundwork / setup phase. This file currently holds only the rules that
> are already locked. The full architecture, design-token, widget/page-composition,
> offline-engine, platform-split, and jank-prevention rules will be added here once the
> groundwork spec is approved. See `docs/superpowers/specs/2026-06-14-groundwork-architecture-design.md`
> (note: `docs/` is gitignored and stays local).

---

## ⛔ Git, commits & attribution — HARD RULES (never violate)

- **NEVER add co-authoring or AI attribution to commits or PRs.** This is absolute.
- Do **not** append `Co-Authored-By: Claude ...` (or any `Co-Authored-By` AI trailer).
- Do **not** add "🤖 Generated with Claude Code" (or any similar generated-by line) to
  commit messages or pull-request bodies.
- Commit messages and PR descriptions contain **only** the human-authored content about
  the change — nothing identifying an AI author.
- This is enforced redundantly via `.claude/settings.json`
  (`includeCoAuthoredBy: false` and `attribution.commit`/`attribution.pr` = `""`).
  If you ever see attribution sneaking in, treat it as a bug and remove it.

## Repo hygiene

- `docs/` is **gitignored** — design specs and notes live there locally and are not
  committed.
- Targets are **Android and Web only** (no iOS/desktop platform folders exist).

## Confirmed tech stack (rationale to be expanded post-spec)

- **State:** Riverpod 2.x (with code generation)
- **Persistence:** Drift (SQL) — native on Android, WASM on Web
- **Offline sync:** OS background sync on Android (WorkManager) + foreground flush on Web
- **Codegen:** embraced (freezed, json_serializable, riverpod_generator, drift)

## Mandatory dev workflow (applies once code exists)

After implementing anything, run in order and fix until clean/green:

1. `dart run build_runner build --delete-conflicting-outputs`
2. `flutter analyze`  → must be clean
3. `flutter test`     → must pass
4. `flutter build apk --release`  → must succeed
