# Journey anti-patterns — do not ship

If a PR matches a row below, fix journey/copy first. Theme passes do not clear these.

## Path & hierarchy

| Anti-pattern | Why it fails | Do instead |
|---|---|---|
| Dense dual cards / competing hero CTAs on path picker | User cannot pick in 3 seconds | Two quiet list rows; one idea each |
| Custom as default after Measure/Narrow | Breaks Auto sacred | Auto home first; Custom is refine |
| Multiple primary buttons same weight | No “one next action” | One prominent; rest bordered/text |
| Burying Bypass in menus only | A/B is core trust | Toolbar + menu bar + ⌘B |
| Audition louder than Measure/Narrow | Optional proof becomes the job | Keep audition secondary / caption |

## Measure

| Anti-pattern | Why it fails | Do instead |
|---|---|---|
| Measure without mic guidance | Bad takes / confusion | Place + volume guidance always visible |
| Empty mic list with no recovery | Dead end | Refresh + Open Settings + Narrow escape |
| Applying a guess curve on bad SNR | Dishonest product | Refuse; keep prior good profile |
| Claiming “lab calibration” | Overclaim | First-pass analyzer honesty |
| Hiding Narrow when mic denied | Blocks toddler path | Always offer Narrow escape |

## Narrow

| Anti-pattern | Why it fails | Do instead |
|---|---|---|
| Calling Narrow “calibrated” / “world-class any speaker” | Lies vs Measure | “Fast · not calibrated” |
| No persist messaging after apply | User fears it vanishes | “Stays until Retry or different speaker” |
| Stacking Narrow on Measure without Retry | Unclear source of truth | Retry / replace prompt; never stack |

## Permissions & System EQ

| Anti-pattern | Why it fails | Do instead |
|---|---|---|
| “System-wide active” while permission/failed/in-app-only | Trust breaker | Phase-honest copy only |
| Permission essay louder than path choices | Noise on first launch | Quiet strip; elevate only when blocked |
| No named Privacy pane | User cannot fix | “Privacy & Security → …” + Open Settings |

## Custom

| Anti-pattern | Why it fails | Do instead |
|---|---|---|
| Solid teal intent bricks / dense pro console | Fights modern minimal + journey | Soft chips; sparse bands |
| Q/type open by default | Overwhelms L0 | Toggle collapsed |
| Limiter as hero billboard | Fear chrome | Footnote / caption |
| No based-on / no Reset to Auto | Lose orientation | Caption + Reset / Undo |

## Process

| Anti-pattern | Why it fails | Do instead |
|---|---|---|
| Theme revamp before journey audit | Chrome churn, same confusion | Decision checklist → copy/flow → then HIG polish |
| ui-ux-pro-max overriding macOS / journey | Wrong visual bar | Defer chrome to macOS; flow to this skill |
| Inventing iPhone / sync / BlackHole UX | Product lock violation | Stop; read `AGENTS.md` |
