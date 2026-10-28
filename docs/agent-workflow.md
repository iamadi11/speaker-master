# Agent workflow

## Installed skill packs

1. **ui-ux-pro-max** — `.agents/skills/ui-ux-pro-max`  
   Source: `nextlevelbuilder/ui-ux-pro-max-skill` (skills.sh). Use for SwiftUI / desktop EQ UI; prefer `--stack` / desktop guidance over web-default layouts.

2. **Matt Pocock skills** — `.agents/skills/{grill-me,tdd,code-review,implement,…}`  
   Source: `mattpocock/skills`. Full engineering set installed. Read **matt-pocock-swift-adapter** before applying TS-module advice to this Swift repo.

3. **autonomous-gap-fix** (custom) — `.agents/skills/autonomous-gap-fix`  
   End-to-end: investigate gaps/bugs → propose/fix → verify → merge to `main` → personal Mac install.

## Trigger: autonomous gap-fix

**Slash:** `/autonomous-gap-fix`  
**Phrase (any of):**

- `Run autonomous gap-fix`
- `Find and ship gaps`
- `Gap-fix then install on this Mac`

Optional scope: append a focus (`Narrow persistence`, `tap permission copy`, …).

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
3. `/code-review` before PR  
4. `/autonomous-gap-fix` for unattended find→fix→ship cycles  

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
