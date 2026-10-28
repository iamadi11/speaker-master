# Product brief (locked)

MacBook-only **system-wide** speaker EQ for personal use.

## Modes

1. **Auto** — user chooses:
   - **Measure**: pick an available mic → guided sweep → correction filters → hold-to-A/B. Honesty: cut-first, capped boost, limiter on.
   - **Narrow**: no mic; apply a narrowed/preset path once; **persist for that speaker** until Retry or a new speaker.
2. **Custom** — pro console, easy UX. Same engine as Auto. Always-visible bypass, undo/reset, linked limiter.

## Architecture intent

- Swift / Core Audio **process taps** (macOS 14.2+; target machine 26.5.1+)
- Soft limiter + boost caps (see future safety sheet)
- No BlackHole / GPL virtual-device embed
- Free Apple ID personal signing; no paid Developer Program dependency

## Out of scope

iPhone app, dual-BT sync product promise, cloud sync, App Store sandbox host, me-too “bass booster” marketing.
