# Speaker Master

MacBook **system-wide** speaker EQ — **Auto** (Measure | Narrow) + pro **Custom** console.

Personal use. Swift / Core Audio **process tap + private aggregate**. Free Apple ID / ad-hoc signing.

## Launch on this Mac

```bash
# Verify domain + build .app + install
swift test --package-path .
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
2. Grant **Screen & System Audio Recording** when macOS prompts — required for Spotify/YouTube/etc.
3. Toggle **Bypass** to A/B. Use **Play audition** to hear the curve in-app without relying on other apps.
4. **Custom** exposes five bands + broadband within `docs/safety-limits.md`.
5. Details: [`docs/system-wide-audio.md`](./docs/system-wide-audio.md).

### Grant permissions

| Need | Path |
|---|---|
| System-wide EQ | System Settings → Privacy & Security → **Screen & System Audio Recording** → Speaker Master |
| Measure mic | System Settings → Privacy & Security → **Microphone** → Speaker Master |

Then **Retry system EQ** in the app if the host still shows permission needed.

## Repo

- GitHub: https://github.com/iamadi11/speaker-master (private)
- Local: `~/Desktop/My Projects/speaker-master`

## Agents

- Conventions: [`AGENTS.md`](./AGENTS.md)
- Workflow: [`docs/agent-workflow.md`](./docs/agent-workflow.md)
- Safety: [`docs/safety-limits.md`](./docs/safety-limits.md)
- System-wide host: [`docs/system-wide-audio.md`](./docs/system-wide-audio.md)

**Skills:** `ui-ux-pro-max` (status + permission recovery), Matt Pocock `tdd` / `implement` + `matt-pocock-swift-adapter` (`AudioTapHosting`, `StereoEQEngine` seams).

## Non-goals

No iPhone/sync product, no BlackHole GPL embed, no sandboxed Mac App Store host, no $99-required distribution, no me-too EQ fluff.
