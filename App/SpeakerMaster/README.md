# Speaker Master (macOS app)

SwiftUI + Core Audio app target. Domain DSP lives in the SPM package at repo root.

## Generate & build

```bash
cd App
xcodegen generate
xcodebuild -project SpeakerMaster.xcodeproj -scheme SpeakerMasterApp -configuration Debug -derivedDataPath ../build build
```

Or from repo root: `Scripts/build-app.sh` / `Scripts/install-personal.sh`

## Permissions

| Permission | Use |
|---|---|
| **Screen & System Audio Recording** | Process tap — system-wide EQ for other apps |
| **Microphone** | Auto Measure |

App Sandbox stays **off** (required for process taps). Free / ad-hoc signing is enough for personal use.

See `docs/system-wide-audio.md`.
