# Agent workflow

## Installed skill packs

1. **macOS design skills** (load **first** for any UI chrome) — `.agents/skills/`  
   - **macos-design** — `ceorkm/macos-design-skill` (MIT). Layout, vibrancy, typography, light/dark. Prefer **modern minimal**.  
   - **macos-patterns** (+ settings-ui, macos-build, auto-update, notch-ui, release) — `fayazara/macos-app-skills` (MIT).  
   - **apple-design** — `dickwu/apple-design-skill`. HIG review; guideline text © Apple Inc.  
   Attribution: `docs/skills-attribution.md`.

2. **ux-journey-pm** (custom) — `.agents/skills/ux-journey-pm`  
   End-to-end user journey: first launch → permissions → Auto Measure|Narrow → Custom → System EQ. Load **after** macOS skills, **before** ui-ux-pro-max.

3. **ui-ux-pro-max** — `.agents/skills/ui-ux-pro-max`  
   Source: `nextlevelbuilder/ui-ux-pro-max-skill`. Use for a11y / interaction support. **Defer** visual direction to macOS skills (no teal-dense override).

4. **Matt Pocock skills** — `.agents/skills/{grill-me,tdd,code-review,implement,…}`  
   Source: `mattpocock/skills`. Read **matt-pocock-swift-adapter** before applying TS-module advice.

5. **autonomous-gap-fix** (custom) — `.agents/skills/autonomous-gap-fix`  
   Investigate → fix → verify → merge → personal Mac install. Runs **after** design + journey decisions.

## UI / journey skill order (hard)

```
macos-design → macos-patterns → apple-design
        → ux-journey-pm
        → ui-ux-pro-max
        → autonomous-gap-fix (ship)
```

Conflicts: macOS skills win on visuals; ux-journey-pm wins on flow/copy/state.

## Trigger: UX journey PM

**Slash:** `/ux-journey-pm`  
**Phrase:** `user journey`, `first launch flow`, `permission UX`, `Auto to Custom path`

## Trigger: autonomous gap-fix

**Slash:** `/autonomous-gap-fix`  
**Phrase (any of):**

- `Run autonomous gap-fix`
- `Find and ship gaps`
- `Gap-fix then install on this Mac`

## Trigger: Apple HIG design review

**Slash:** `/apple-design`  
**Phrase:** `Review against Apple HIG`, `macOS design audit`, `HIG pass on this screen`

## Safety gates (hard)

| Gate | Rule |
|---|---|
| Verify before merge | CI / local `swift test` (+ `xcodebuild` when app target builds) must be **green** |
| Verify before install | `./Scripts/smoke-mac.sh full` green; install script refuses otherwise |
| No force-push to `main` | Ever |
| Merge path | PR → required checks → merge (squash or merge commit) |
| Install scope | **This Mac only**, free/ad-hoc signing |
| Product lock | Do not expand into iPhone/sync/BlackHole |
| Visual bar | Modern minimal macOS — sparse chrome over dense pro clutter |

## Recommended daily loop

1. `/grill-me` or `/grill-with-docs` on ambiguous work  
2. UI → macos-design / macos-patterns / apple-design → `/ux-journey-pm` → ui-ux-pro-max a11y  
3. `/to-spec` → `/tdd` or `/implement`  
4. `/code-review` before PR  
5. `/autonomous-gap-fix` for unattended find→fix→ship cycles  

## Branch protection (manual — enable in GitHub)

Repo is private: `iamadi11/speaker-master`.

Recommended settings on `main`:

- Require pull request before merging
- Require status checks: `CI` workflow (`build-and-test`)
- Restrict force pushes

Until branch protection UI is flipped, agents must still obey the safety gates above.

## Issue tracker

Default: **GitHub Issues** on this repo. Local scratch optional under `.scratch/` for private notes.
