---
name: autonomous-gap-fix
description: "Autonomous product-gap and bug finder for speaker-master. Investigates gaps/bugs, proposes and applies fixes, runs verification, merges to main only when green, then installs the app on this Mac with free signing. Trigger: /autonomous-gap-fix, 'Run autonomous gap-fix', 'Find and ship gaps', or 'Gap-fix then install on this Mac'."
---

# Autonomous gap-fix

End-to-end ship loop for **speaker-master** on the owner’s Mac.

## Trigger phrases

- `/autonomous-gap-fix`
- `Run autonomous gap-fix`
- `Find and ship gaps`
- `Gap-fix then install on this Mac`

## Hard rules (never violate)

1. **Never merge without green verification** (`swift test`, and `xcodebuild` build when the app scheme exists / CI green).
2. **Never install without verify** — `Scripts/install-personal.sh` must be preceded by a passing verify step in the same run.
3. **Never force-push `main`**.
4. **Personal Mac install only** — free / ad-hoc signing; no paid Apple Developer assumptions; no notarization unless the user explicitly expands scope later.
5. Obey product lock in `AGENTS.md` (Mac-only, no BlackHole GPL embed, no sync product, world-class bar).

## Skill order when the gap is UI / journey

Before inventing chrome or flows:

1. `macos-design` / `macos-patterns` / `apple-design` — modern minimal native look  
2. `ux-journey-pm` — journey map + checklist  
3. `ui-ux-pro-max` — a11y only (defer visuals to macOS skills)  
4. Then this skill’s ship loop  

Visual bar: sparse macOS chrome over dense teal Custom clutter (`AGENTS.md`).

## Process

### 1. Investigate

- Read `AGENTS.md`, `docs/product-brief.md`, `GLOSSARY.md`, open issues, recent PRs, failing tests, TODO/FIXME, and known gaps in `docs/`.
- Prefer user-visible product gaps (Auto Measure|Narrow, Custom, taps permissions, persistence) over cosmetic refactors.
- For UI gaps, also read `ux-journey-pm` + macOS design skills before proposing chrome.
- Write a short gap list with severity. Confirm scope if more than one high-risk change.

### 2. Propose / fix

- Work on branch `cursor/gap-fix-<short>-1c86` (or continue an existing assigned branch).
- Smallest vertical slice that closes one gap. Use `tdd` / `diagnosing-bugs` / `implement` as needed.
- No drive-by unrelated edits.

### 3. Verify (required)

Run from repo root:

```bash
swift test --package-path .
# When App/Xcode scheme is present:
xcodebuild -scheme SpeakerMaster -destination 'platform=macOS' build
# Preferred crash gate before install:
./Scripts/smoke-mac.sh full
```

If CI exists on the PR, wait for green. **Stop here on failure** — do not merge, do not install.

### 4. Merge to main

- Open or update a PR into `main`.
- Merge only after verification is green (PR checks and/or local commands above).
- Prefer squash merge. Never `--force` on `main`.

### 5. Install on this Mac

Only after merge (or after green verify on the branch the user asked to install):

```bash
./Scripts/install-personal.sh
```

Report: what fixed, verify evidence, merge SHA, install path / result.

## Abort conditions

- Verification red
- Change would require $99 program, BlackHole embed, iPhone/sync scope, or force-push
- User / product prefs conflict — surface blocker instead of shipping
