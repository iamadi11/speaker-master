# Journey checklist (ship gate)

Use before merging UI/journey PRs.

## First launch / path picker
- [ ] Auto is default tab
- [ ] Measure vs Narrow each have one clear subtitle; Narrow not called calibrated
- [ ] Output identity visible (toolbar chip)
- [ ] Headphone warning only when relevant
- [ ] System EQ status present but not louder than the two paths

## Permissions
- [ ] Mic permission path only when Measure needs it
- [ ] Screen & System Audio: empty-state title/body/actions match `SystemEQEmptyStateCopy`
- [ ] Never show “system-wide active” when phase is permission / failed / in-app-only

## Measure
- [ ] Mic list bound to HAL catalog; Refresh works
- [ ] Primary = Run measure; Back returns to path picker
- [ ] Bad take: honest note; no invented curve
- [ ] Success lands on Auto home with path label Measure

## Narrow
- [ ] Suggested preset visible
- [ ] Apply → Auto home; profile persists for output UID
- [ ] Retry clears persistence and returns toward path picker

## Auto home
- [ ] “On for: {speaker}” + path label
- [ ] Bypass, Retry, Open Custom — no extra chrome
- [ ] Audition optional / secondary

## Custom
- [ ] Based-on label quiet (not accent billboard)
- [ ] Intents: soft selection, not dense filled teal grid
- [ ] Advanced Q/type collapsed by default
- [ ] Undo / Reset to Auto / Flat reachable
- [ ] Limiter/headroom as caption, not hero

## Global
- [ ] Toolbar: Mode segmented + Bypass + output
- [ ] Shortcuts: ⌘1 Auto, ⌘2 Custom, ⌘B Bypass
- [ ] Menu bar: Bypass, Audition, Show, Quit
- [ ] Reduced motion: Bypass toggles instead of hold
- [ ] `smoke-mac.sh full` green before install
