# Product brief (locked)

MacBook-only **system-wide** speaker EQ for personal use.

## Modes

1. **Auto** — user chooses:
   - **Measure**: pick an available mic → guided sweep → correction filters → hold-to-A/B. Honesty: cut-first, capped boost, limiter on.
   - **Narrow**: no mic; apply a narrowed/preset path once; **persist for that speaker** until Retry or a new speaker.
2. **Custom** — pro console, easy UX. Same engine as Auto. Always-visible bypass, undo/reset, linked limiter.

## Architecture intent

- Swift / Core Audio **process taps** (macOS 14.2+; target machine 26.5.1+)
- Soft limiter + boost caps (see `docs/safety-limits.md`)
- No BlackHole / GPL virtual-device embed
- Free Apple ID personal signing; no paid Developer Program dependency

## Out of scope

iPhone app, dual-BT sync product promise, cloud sync, App Store sandbox host, me-too “bass booster” marketing.

## Phase-1 validation docs

| Doc | Role |
|---|---|
| `docs/safety-limits.md` | Frozen safety caps |
| `docs/paper-ux-flows.md` | Auto + Custom paper flows |
| `docs/narrow-presets-sketch.md` | Narrow taxonomy + honesty |
| `docs/listening-trial-guide.md` | User-run A/B/C listening protocol |
| `docs/competitive-gap-note.md` | Dual-mode gap still open |
| `docs/phase-1-checklist.md` | Gate checkboxes in-repo |
