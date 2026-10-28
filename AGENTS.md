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
3. UI/UX work → `ui-ux-pro-max` (SwiftUI / desktop, not web defaults).
4. Autonomous find→fix→verify→merge→install → **only** via `autonomous-gap-fix` skill and its safety gates.
5. Small vertical slices. No speculative DSP until safety sheet + listening gates allow.
6. Never force-push `main`. Never merge without green verification. Never install without verify.

## Skill index (project)

| Skill | Path | When |
|---|---|---|
| ui-ux-pro-max | `.agents/skills/ui-ux-pro-max` | Design / SwiftUI / a11y |
| Matt Pocock set | `.agents/skills/*` (grill-me, tdd, …) | Engineering rigor |
| Swift adapter | `.agents/skills/matt-pocock-swift-adapter` | Map TS patterns → Swift |
| Autonomous gap-fix | `.agents/skills/autonomous-gap-fix` | Investigate → fix → verify → merge → install |

Trigger docs: `docs/agent-workflow.md`.

## Verification baseline

```bash
swift test --package-path .
# when Xcode app target exists:
xcodebuild -scheme SpeakerMaster -destination 'platform=macOS' build
```

Personal install (after green verify only): see `Scripts/install-personal.sh`.
