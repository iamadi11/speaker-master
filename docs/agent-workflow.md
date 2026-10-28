# Agent workflow

## Installed skill packs

1. **ui-ux-pro-max** — `.agents/skills/ui-ux-pro-max`  
   Source: `nextlevelbuilder/ui-ux-pro-max-skill` (skills.sh). Use for SwiftUI / desktop EQ UI; prefer `--stack` / desktop guidance over web-default layouts.

2. **Matt Pocock skills** — `.agents/skills/{grill-me,tdd,code-review,implement,…}`  
   Source: `mattpocock/skills`. Full engineering set installed. Read **matt-pocock-swift-adapter** before applying TS-module advice to this Swift repo.

3. **autonomous-gap-fix** (custom) — `.agents/skills/autonomous-gap-fix`  
   End-to-end: investigate gaps/bugs → propose/fix → verify → merge to `main` → personal Mac install.

4. **macOS design skills** (vendored under `.agents/skills/`)  
   - **macos-design** — `ceorkm/macos-design-skill` (MIT). Layout formula, vibrancy, typography, light/dark.  
   - **macos-patterns** (+ settings-ui, macos-build, auto-update, notch-ui, release) — `fayazara/macos-app-skills` (MIT). Native AppKit/SwiftUI patterns. (`macos-build` = upstream `build/`)  
   - **apple-design** — `dickwu/apple-design-skill`. HIG-grounded design review; guideline text © Apple Inc.  
   Full attribution: `docs/skills-attribution.md`.

## UI / macOS chrome workflow

When changing SwiftUI chrome, toolbars, materials, typography, or controls:

1. Load `ui-ux-pro-max` **and** `macos-design` (`references/layout-and-composition.md`, `visual-design.md` as needed).
2. Load `macos-patterns` before inventing window / menu-bar / shortcut behavior.
3. Run an `/apple-design` pass against `references/hig/designing-for-macos.md` plus relevant pages (`toolbars.md`, `materials.md`, `typography.md`, `color.md`, `buttons.md`, `keyboards.md`).
4. Prefer system toolbar + materials over custom web-like chrome. Keep Auto / Custom product lock intact.

## Trigger: autonomous gap-fix

**Slash:** `/autonomous-gap-fix`  
**Phrase (any of):**

- `Run autonomous gap-fix`
- `Find and ship gaps`
- `Gap-fix then install on this Mac`

Optional scope: append a focus (`Narrow persistence`, `tap permission copy`, …).

## Trigger: Apple HIG design review

**Slash:** `/apple-design`  
**Phrase:** `Review against Apple HIG`, `macOS design audit`, `HIG pass on this screen`

## Safety gates (hard)

| Gate | Rule |
|---|---|
| Verify before merge | CI / local `swift test` (+ `xcodebuild` when app target builds) must be **green** |
| Verify before install | Same green bar; install script refuses otherwise |
| No force-push to `main` | Ever |
| Merge path | PR → required checks → merge (squash or merge commit). Direct push to `main` only for docs-only emergency with explicit user OK |
| Install scope | **This Mac only**, free/ad-hoc signing — never notarize/$99 flow unless user asks later |
| Product lock | Do not expand into iPhone/sync/BlackHole |

## Recommended daily loop

1. `/grill-me` or `/grill-with-docs` on ambiguous work  
2. `/to-spec` → `/tdd` or `/implement`  
3. macOS UI → macos-design + macos-patterns + ui-ux-pro-max → `/apple-design` before PR  
4. `/code-review` before PR  
5. `/autonomous-gap-fix` for unattended find→fix→ship cycles  

## Branch protection (manual — enable in GitHub)

Repo is private: `iamadi11/speaker-master`.

Recommended settings on `main`:

- Require pull request before merging
- Require status checks: `CI` workflow (`build-and-test`)
- Restrict force pushes
- Do **not** allow admin bypass for force-push in day-to-day use

Until branch protection UI is flipped, agents must still obey the safety gates above.

## Issue tracker

Default: **GitHub Issues** on this repo. Local scratch optional under `.scratch/` for private notes.
