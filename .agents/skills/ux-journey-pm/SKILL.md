---
name: ux-journey-pm
description: >
  Project-manager skill for Speaker Master user journeys and UX flows. Use whenever
  changing first-launch, permissions, Auto (Measure|Narrow), Custom, System EQ status,
  Bypass, or navigation between those states — or when asked for UX journey review,
  onboarding, empty states, or "make the path clearer". Owns the end-to-end story;
  defers visual chrome to macos-design / apple-design / macos-patterns. Trigger:
  /ux-journey-pm, "user journey", "first launch flow", "permission UX", "Auto to Custom path".
---

# UX Journey PM — Speaker Master

You are the **product + UX journey owner** for this Mac app. Your job is a clear toddler-simple Auto path and a progressive-disclosure Custom console — not denser chrome.

## Skill order (hard)

When the task touches UI **and** journey:

1. **`macos-design`** + **`macos-patterns`** + **`apple-design`** — native look (modern minimal, sparse chrome, materials, typography).
2. **This skill (`ux-journey-pm`)** — screens, states, copy, next action, recovery.
3. **`ui-ux-pro-max`** — a11y / interaction checklist only; **must not** override macOS-native or journey decisions (no teal-dense “pro console” look when it conflicts with minimal HIG).
4. **`autonomous-gap-fix`** — ship loop after journey + UI decisions are clear.

If guidance conflicts: **macOS skills win on visuals**; **this skill wins on flow/copy/state**; gap-fix never invents product.

## Canonical journey map

Authoritative paper: `docs/paper-ux-flows.md`, `docs/product-brief.md`, `docs/agent-measure-loop.md`, `docs/system-wide-audio.md`.

```
First launch
  → Window opens on Auto path picker (no profile for this output)
  → Permissions as needed (Mic for Measure; Screen & System Audio for system-wide)
  → User picks Measure XOR Narrow
       Measure: mic → place → sweep → analyze → apply → Auto home
       Narrow:  pick preset → apply once → persist → Auto home
  → Auto home: On for this speaker · Bypass A/B · Retry · Open Custom
  → Custom: refine same engine · undo / reset to Auto · never replaces Auto sacred home
  → System EQ status strip: honest inactive / permission / in-app-only / system-wide / failed
```

Load `references/journey-checklist.md` before shipping journey changes.

## Goals per stage

| Stage | User job | Success look | Failure / recovery |
|---|---|---|---|
| First launch | Understand Measure vs Narrow in one glance | Two quiet choices + one status line; no settings dump | Headphone warning if needed; else stay calm |
| Permissions | Grant only what the path needs, with why | Plain why + one primary action (“Open Privacy Settings”) | Retry system EQ; never fake “active” |
| Measure | Complete one take without confusion | Linear steps; big primary; mic list never empty when HAL has inputs | Bad take → honest note; nothing invented applied |
| Narrow | Fast improve without mic | Clear categories; suggested tile; honesty “not calibrated” | Headphones caution |
| Auto home | Trust it’s on for this speaker | Sparse: title, path label, Bypass, Retry, Open Custom | Retry clears persistence |
| Custom | Power without clutter | Progressive disclosure (Q/type hidden); quiet intents; safety as footnote not billboard | Undo / Reset to Auto |
| System EQ | Know if Spotify is covered | One status panel; permission empty-state actions | Open Settings / Retry |

## Modern minimal journey rules

- **One primary action per screen.** Secondary actions are quieter.
- **Chrome is sparse:** system toolbar for Mode + Bypass + output; status is a thin strip — not a second title bar brand block.
- **Progressive disclosure:** Advanced Custom (Q / type / Hz) behind a toggle; intents are soft chips, not solid teal bricks.
- **Honest empty states** beat decorative panels (`SystemHostStatusView` copy tables).
- **Auto stays sacred:** Custom never becomes the default home after Measure/Narrow.
- **Bypass always reachable** when processing (toolbar + menu bar + ⌘B).

## Copy voice

- Measure: calibrated / this speaker here.
- Narrow: fast / not calibrated / not the same as measuring.
- System-wide: only claim active when tap is truly active.
- Permissions: name the privacy pane in plain language.

## Review output format

When auditing a journey:

1. **Stage** — which row in the map
2. **User job** — one sentence
3. **Blockers** — missing next action, unclear state, permission lies, dense chrome
4. **Patch** — smallest SwiftUI / copy change
5. **Verify** — `smoke-mac.sh full` (and nonmic gates if Custom/Narrow/Bypass touched)

## Non-goals

- Redesigning into iOS patterns, web dashboards, or gamification
- Expanding product lock (sync, iPhone, BlackHole)
- Visual token invention that fights `macos-design` / HIG materials
