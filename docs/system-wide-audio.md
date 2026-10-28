# System-wide audio (process tap)

**Status:** Implemented host path (SM-21)  
**OS:** macOS 14.2+ (process taps); validated target **26.5.1 (25F80)**  
**Signing:** Free / ad-hoc personal — **App Sandbox must stay off**

## How it works

```
Other apps (Spotify, Safari, …)
        │
        ▼
 Core Audio process tap (device-scoped, muted, private)
        │
        ▼
 Private aggregate  ── clock master = real output
   · tap input (drift-compensated, max quality)
   · physical output
        │
        ▼
 One IOProc → StereoEQEngine (safety-capped PEQ + limiter)
        │
        ▼
 Speakers / BT box
```

Speaker Master **excludes its own process** from the tap so in-app audition is not double-EQed. Audition still uses `InAppEQPlayer`.

No BlackHole / virtual HAL driver. If the app quits or crashes, the tap is destroyed and apps play normally again (safety sheet: no mute-until-reboot trap).

## Permissions

| Permission | Why | Where |
|---|---|---|
| **Screen & System Audio Recording** | Process tap capture of other apps’ audio | System Settings → Privacy & Security → Screen & System Audio Recording → **Speaker Master** |
| **Microphone** | Auto → Measure only | System Settings → Privacy & Security → Microphone |

After granting system audio, use **Retry system EQ** in the app (or re-apply Narrow / Measure / Custom).

Deep link used by the app:

`x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture`

## Install / launch

```bash
cd "~/Desktop/My Projects/speaker-master"
./Scripts/install-personal.sh
# .app paths:
#   build/Build/Products/Debug/SpeakerMaster.app
#   ~/Applications/SpeakerMaster.app
```

Ad-hoc sign is required after each copy so TCC binds to the installed bundle.

## Honest blockers / limits

| Topic | Reality |
|---|---|
| **Sandbox / Mac App Store** | Process taps are unavailable to sandboxed apps — personal / direct distribution only |
| **TCC denial** | Host reports permission needed; in-app audition still works |
| **Bluetooth** | Single-clock aggregate is required to avoid pitch warble; still subject to BT codec / device quirks |
| **Duplex USB interfaces** | Tap streams are the trailing aggregate inputs; hardware mic buffers are skipped |
| **Headphone outputs** | Narrow warns; system-wide still applies if you proceed |
| **Paid Developer ID** | Not required for personal use; Gatekeeper may warn on first open — right-click → Open |

## Architecture credit

Public API: Apple Core Audio taps (`AudioHardwareCreateProcessTap`, private aggregate tap list).  
Single-clock topology guidance also documented by MIT-licensed [CoreAudioTapKit](https://github.com/CJStanfield/CoreAudioTapKit); Speaker Master implements its own host + `StereoEQEngine` DSP under `docs/safety-limits.md`.
