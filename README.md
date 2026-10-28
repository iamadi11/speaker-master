# Speaker Master

MacBook **system-wide** speaker EQ — **Auto** (Measure | Narrow) + pro **Custom** console.

Personal use. Swift / Core Audio. Free Apple ID / ad-hoc signing.

## Launch on this Mac

```bash
# Verify domain + build .app
swift test --package-path .
./Scripts/build-app.sh

# Install to ~/Applications and open
./Scripts/install-personal.sh
```

Built app path (after build):

`build/Build/Products/Debug/SpeakerMaster.app`

Installed copy:

`~/Applications/SpeakerMaster.app`

Or open the Xcode project:

```bash
cd App && xcodegen generate && open SpeakerMaster.xcodeproj
```

### First-run tips

1. Pick **Auto → Narrow** for a fast audible change (no mic), or **Measure** with mic permission.
2. Tap **Play audition** and toggle **Bypass** to A/B the EQ.
3. **Custom** exposes five bands + broadband within `docs/safety-limits.md`.
4. v1 proves EQ via **in-app audition**; system-wide process tap is staged next (no BlackHole).

## Repo

- GitHub: https://github.com/iamadi11/speaker-master (private)
- Local: `~/Desktop/My Projects/speaker-master`

## Agents

- Conventions: [`AGENTS.md`](./AGENTS.md)
- Workflow: [`docs/agent-workflow.md`](./docs/agent-workflow.md)
- Safety: [`docs/safety-limits.md`](./docs/safety-limits.md)

**Skills used for v1:** `ui-ux-pro-max` (desktop/SwiftUI chrome), Matt Pocock `tdd` / `implement` + `matt-pocock-swift-adapter` (domain seams). `/autonomous-gap-fix` only after verify for polish.

## Non-goals

No iPhone/sync product, no BlackHole GPL embed, no $99-required distribution, no me-too EQ fluff.
