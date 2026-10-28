---
name: matt-pocock-swift-adapter
description: "Maps Matt Pocock engineering skills (grill-me, tdd, codebase-design, etc.) onto this Swift/macOS speaker-master repo — what applies, what to adapt, what to skip."
---

# Matt Pocock skills → Swift / macOS

This repo installed `mattpocock/skills` under `.agents/skills/`. Those skills are TypeScript-flavored in examples; **the process still applies**. Use this adapter so agents don’t invent a Node/TS stack.

## Applies as-is (process)

| Skill | Use here |
|---|---|
| `grill-me` / `grill-with-docs` | Ambiguous EQ/UX/policy work before coding |
| `to-spec` / `to-tickets` / `triage` | Specs & GitHub Issues |
| `tdd` | XCTest / Swift Testing — red→green at public seams |
| `implement` / `implement-spec` | Vertical slices |
| `code-review` / `diagnosing-bugs` | PR and bug loops |
| `domain-modeling` / `codebase-design` | Module boundaries (EQ engine vs UI vs Core Audio adapters) |
| `handoff` / `writing-for-agents` | Agent docs |
| `prototype` | Throwaway spikes (mark clearly; don’t ship) |

## Adapt (don’t follow TS literally)

| Pattern in Matt skills | Swift / this repo |
|---|---|
| `pnpm` / `vitest` / `tsc` | `swift test`, `xcodebuild`, Swift 6 concurrency |
| Deep TS modules / `setup-ts-deep-modules` | SPM targets + clear `internal`/`public` API; **skip shoehorn / TS-only skills** |
| `package.json` workspaces | Single SPM package + thin app target |
| Node seams / HTTP handlers | Protocol-oriented seams: `EQEngine`, `AudioTapHosting`, `SpeakerProfileStore` |
| Snapshot / DOM tests | Prefer behavior tests on DSP math + profile persistence; UI tests sparingly |

## Skip or avoid on this product

- `migrate-to-shoehorn`, `setup-ts-deep-modules`, `scaffold-exercises` — TypeScript teaching tooling
- Anything that assumes web deploy, npm publish, or browser a11y as the primary surface (use `ui-ux-pro-max` with **desktop / SwiftUI** framing instead)
- Expanding scope into iPhone or sync “because the skill said ship”

## Recommended first session

1. `/grill-with-docs` for safety sheet / Measure flow if still open  
2. `/tdd` on pure Swift domain (gain caps, profile keying) before Core Audio  
3. `/code-review` before any merge  
4. `/autonomous-gap-fix` only with its verify→merge→install gates  

## Seams to prefer (when testing)

1. Filter coefficient / curve math (pure)  
2. Per-speaker profile persistence keying  
3. Safety limiter / boost cap policy  
4. Adapter boundaries around Core Audio taps (mock the host in unit tests)
