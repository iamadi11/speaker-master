# Third-party agent skills — attribution

Speaker Master vendors agent skills under `.agents/skills/`. Existing packs (**ui-ux-pro-max**, **matt-pocock**, **autonomous-gap-fix**) remain. This document attributes the **macOS design** skill sources added for native HIG work.

## ceorkm / macos-design-skill

| | |
|---|---|
| Upstream | https://github.com/ceorkm/macos-design-skill |
| Installed as | `.agents/skills/macos-design` |
| License | **MIT** (see `LICENSE` in that folder; stated in upstream README) |
| Use | Native macOS layout, visual design, interaction patterns |

## fayazara / macos-app-skills

| | |
|---|---|
| Upstream | https://github.com/fayazara/macos-app-skills |
| Installed as | `.agents/skills/{macos-patterns,settings-ui,macos-build,auto-update,notch-ui,release}` plus pack note in `macos-app-skills-pack/` (`macos-build` = upstream `build/`, renamed to avoid `.gitignore` `build/`) |
| License | **MIT** (upstream README; each skill folder has a `LICENSE`) |
| Use | Native SwiftUI/AppKit patterns, settings windows, build/release helpers |

## dickwu / apple-design-skill

| | |
|---|---|
| Upstream | https://github.com/dickwu/apple-design-skill |
| Installed as | `.agents/skills/apple-design` |
| License / provenance | Skill packaging provided as-is by upstream. **Guideline text in `references/hig/` belongs to Apple Inc.**, reproduced from the public [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/) for AI-assisted review. Not affiliated with or endorsed by Apple. See `LICENSE-NOTE.md` in the skill folder. |
| Use | HIG-grounded design review (`/apple-design`) |

## Project-authored skills

### ux-journey-pm

| | |
|---|---|
| Path | `.agents/skills/ux-journey-pm` |
| License | MIT (project) |
| Role | User journey PM: first launch → permissions → Auto Measure\|Narrow → Custom → System EQ. Loads after macOS design skills, before ui-ux-pro-max. |

## Preserved project skills

- `.agents/skills/ui-ux-pro-max` — defers visual direction to macOS skills for this repo
- Matt Pocock set (grill-me, tdd, code-review, implement, …) + `matt-pocock-swift-adapter`
- `.agents/skills/autonomous-gap-fix` — ship loop after design + journey

## Skill load order (UI work)

1. macos-design / macos-patterns / apple-design  
2. ux-journey-pm  
3. ui-ux-pro-max  
4. autonomous-gap-fix  

Hashes for vendored entrypoints are recorded in `skills-lock.json`.
