# Speaker Master (macOS app)

SwiftUI + Core Audio app target. Domain DSP lives in the SPM package at repo root.

## Generate & build

```bash
cd App
xcodegen generate
xcodebuild -project SpeakerMaster.xcodeproj -scheme SpeakerMaster -configuration Debug -derivedDataPath ../build build
```

Or from repo root: `Scripts/build-app.sh`

## Permissions

- Microphone — Auto Measure
- Screen & System Audio Recording — future system-wide process tap (v1 ships in-app audition host)

Personal install: `Scripts/install-personal.sh` after green verify.
