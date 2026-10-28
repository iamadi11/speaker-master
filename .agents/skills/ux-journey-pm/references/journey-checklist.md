# Journey checklist (ship gate)

Use before merging UI/journey PRs. Load `screen-states.md` + `anti-patterns.md` with this file.

## Decision gate (required)

- [ ] Stated stage + user job + one next action (see skill Decision checklist)
- [ ] Success / fail / empty / denied considered
- [ ] No product-lock invention
- [ ] Journey/copy fixed before any theme churn

## First launch / path picker

- [ ] Auto is default tab
- [ ] Empty / no-profile state shows picker (not a fake “On for…”)
- [ ] Measure vs Narrow each have one clear subtitle; Narrow not called calibrated
- [ ] Output identity visible (toolbar chip)
- [ ] Headphone warning only when relevant
- [ ] System EQ status present but not louder than the two paths
- [ ] Audition optional / secondary — not competing as a third path

## Permissions

- [ ] Mic permission path only when Measure needs it
- [ ] Denied mic: Open Microphone settings + Ask again / Refresh + Narrow escape
- [ ] Screen & System Audio: empty-state title/body/actions match `SystemEQEmptyStateCopy`
- [ ] Never show “system-wide active” when phase is permission / failed / in-app-only

## Measure

- [ ] Mic list bound to HAL catalog; Refresh works
- [ ] Place / volume guidance visible before Run
- [ ] Primary = Play & measure; phase labels Listening… / Analyzing…
- [ ] Back returns to path picker
- [ ] Bad take: honest note; no invented curve; prior good profile kept
- [ ] Success lands on Auto home with path label Measure + persist line

## Narrow

- [ ] Suggested preset visible
- [ ] Honesty: not calibrated / not the same as Measure
- [ ] Apply → Auto home; profile persists for output UID
- [ ] Home copy: stays until Retry or different speaker
- [ ] Retry clears persistence and returns toward path picker

## Auto home

- [ ] “On for: {speaker}” + path label + persist honesty
- [ ] Bypass reachable (toolbar / ⌘B) — A/B is the trust action
- [ ] Retry + Open Custom — no extra chrome piles
- [ ] Audition optional / secondary
- [ ] Measure quality note when relevant (good / cautious)

## Custom

- [ ] Based-on label quiet (not accent billboard)
- [ ] Intents: soft selection, not dense filled teal grid
- [ ] Advanced Q/type collapsed by default
- [ ] Undo / Reset to Auto / Flat reachable
- [ ] Limiter/headroom as caption, not hero
- [ ] Mode switch back to Auto keeps profile orientation

## Global

- [ ] Toolbar: Mode segmented + Bypass + output
- [ ] Shortcuts: ⌘1 Auto, ⌘2 Custom, ⌘B Bypass
- [ ] Menu bar: Bypass, Audition, Show, Quit
- [ ] Reduced motion: Bypass toggles instead of hold
- [ ] New speaker (UID change) → path picker; old profile not auto-applied
- [ ] `smoke-mac.sh full` green before install
