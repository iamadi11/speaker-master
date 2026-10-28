# Empty Measure mic picker fix

## Root cause (not TCC)

Measure showed a blank mic control even when Microphone was already granted.

1. **UI observation** — `MicRecorder` is a nested `ObservableObject` inside `AppModel`. Views only `@EnvironmentObject` the parent, so `devices` / `selectedDeviceID` updates did not redraw Measure.
2. **Menu picker binding** — selection used `selectedDeviceID ?? ""`. A non-matching `""` tag blanks the macOS `.menu` picker while `devices` is non-empty (Play & measure stayed enabled).
3. **Enumeration** — listing went through `AVCaptureDevice.DiscoverySession`. Measure bind path already uses Core Audio UIDs; HAL `MicInputCatalog` (input-stream devices only) is the source of truth and matches record binding. App aggregate tap devices are filtered out.

Not a missing entitlement: `NSMicrophoneUsageDescription` and `com.apple.security.device.audio-input` were already present; sandbox off.

## Fix

- `MicInputCatalog.listInputs()` via Core Audio HAL
- Forward nested `objectWillChange` from mic/output/player/systemHost → `AppModel`
- Clamp picker selection to a live device UID; clear empty states when the list is truly empty
- `--dump-mics` prints catalog + selection (exit 0 when non-empty with selection)

## Verify

```bash
./Scripts/smoke-mac.sh full
./build/Build/Products/Debug/SpeakerMaster.app/Contents/MacOS/SpeakerMaster --dump-mics
# expect mic_count≥1 and mic* Built-in (or other input)
./Scripts/install-personal.sh   # only after smoke passes
```
