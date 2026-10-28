# Speaker Master — Agent Guide

MacBook-only **system-wide** speaker EQ. Personal use. Free Apple ID / local signing only.

## Product lock (do not invent conflicting product)

| Decision | Locked |
|---|---|
| Platform | **MacBook only** — no iPhone, no sync product, no PWA |
| Job | Make the **currently connected speaker** sound as good as software safely can — system-wide |
| Auto | User chooses **Measure** (mic) **or** **Narrow** (presets) |
| Measure | Record (user-selected mic) → analyze → apply best safe Auto EQ; see `docs/agent-measure-loop.md` |
| Narrow | No mic; apply once; **persist per speaker** until Retry / new speaker |
| Custom | Pro console, easy UX — progressive disclosure, not dumbed-down |
| Host | Core Audio **process taps** (user macOS 26.5.1+) |
| Signing | Personal / free provisioning — **no $99** assumption |
| Sync | **Not a product promise** |

**Quality bar:** world-class only. No me-too preset-EQ fluff in copy or claims. “Calibrated / world-class for this speaker” language attaches to **Measure**; Narrow is the fast no-mic shortcut.

**Visual bar:** **modern minimal** macOS — sparse chrome, native materials/typography, quiet Custom. Prefer HIG/native skills over dense teal “pro console” chrome when they conflict.

## Non-goals

- Dual Bluetooth sync / Party Connect / AirPlay multi-room as features
- Embedding **BlackHole** or other GPL virtual devices
- Mac App Store sandbox host for system-wide taps
- Paid Apple Developer Program dependency
- Cloud sync, accounts, analytics, gamification

## Stack

- Native **Swift** + SwiftUI + Core Audio
- SPM package `SpeakerMaster` for DSP / domain; app target thin
- Xcode 26+ / Swift 6

## How agents should work

1. Read this file + `docs/product-brief.md` + `GLOSSARY.md` before changing product behavior.
2. Prefer Matt Pocock skills for process (`grill-me`, `tdd`, `code-review`, `implement`, …). See `.agents/skills/matt-pocock-swift-adapter/` for Swift applicability.
3. **UI + journey skill order (hard):**
   1. **macOS design skills first** — `macos-design` → `macos-patterns` → `apple-design` (modern minimal / HIG)
   2. **`ux-journey-pm`** — first launch → permissions → Auto Measure|Narrow → Custom → System EQ
   3. **`ui-ux-pro-max`** — a11y / interaction support only; defer visuals to macOS skills
   4. **`autonomous-gap-fix`** — verify → merge → install after the above
4. Autonomous find→fix→verify→merge→install → **only** via `autonomous-gap-fix` and its safety gates.
5. Small vertical slices. No speculative DSP until safety sheet + listening gates allow.
6. Never force-push `main`. Never merge without green verification. Never install without verify.

## Skill index (project)

| Skill | Path | When |
|---|---|---|
| macos-design | `.agents/skills/macos-design` | **First** for native layout, materials, typography |
| macos-patterns | `.agents/skills/macos-patterns` | Menu bar, panels, shortcuts, activation |
| apple-design | `.agents/skills/apple-design` | HIG audit (`/apple-design`) |
| settings-ui | `.agents/skills/settings-ui` | Preferences window when needed |
| ux-journey-pm | `.agents/skills/ux-journey-pm` | **Second** — user journey / flows / copy |
| ui-ux-pro-max | `.agents/skills/ui-ux-pro-max` | **Third** — a11y / interaction; defer chrome to macOS skills |
| macos-build / release / auto-update / notch-ui | `.agents/skills/{macos-build,release,auto-update,notch-ui}` | Ship tooling (`macos-build` = upstream `build`) |
| Matt Pocock set | `.agents/skills/*` (grill-me, tdd, …) | Engineering rigor |
| Swift adapter | `.agents/skills/matt-pocock-swift-adapter` | Map TS patterns → Swift |
| Autonomous gap-fix | `.agents/skills/autonomous-gap-fix` | Investigate → fix → verify → merge → install |

Attribution + licenses: `docs/skills-attribution.md`. Trigger docs: `docs/agent-workflow.md`.

## Verification baseline

```bash
swift test --package-path .
# when Xcode app target exists:
xcodebuild -scheme SpeakerMaster -destination 'platform=macOS' build
./Scripts/smoke-mac.sh full   # before personal install
```

Personal install (after green verify only): see `Scripts/install-personal.sh`.
