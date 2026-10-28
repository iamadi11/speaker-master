# Paper UX flows — Auto + Custom

**Project:** speaker-master  
**Status:** Paper / IA only — no production UI code  
**Date:** 2026-10-28  
**Locks:** Mac-only · Auto = Measure | Narrow · Narrow persists until Retry · Custom = easy pro console · selectable mics · system-wide · personal use

Use this doc for walkthroughs and Figma-level screens. Competitive bar: Reflect / HouseCurve honesty for Auto; SoundSource clarity + eqMac Expert depth for Custom — without ACE installs or a raw DAW wall.

---

## 0. Global chrome (always)

| Element | Behavior |
|---|---|
| **Mode tabs / home** | **Auto** (default) · **Custom** |
| **Bypass** | Always visible when processing active — hold or toggle “Before” |
| **Output chip** | Current speaker / Core Audio output name (tap → system Sound settings hint if wrong device) |
| **Status** | Idle · Measuring · Narrow applied · Custom editing · Needs permission · Error |
| **Menu bar** | Bypass, open app, quit — toddler path never depends on menu bar |

Auto stays sacred: Custom never replaces the one-run Auto home.

---

## 1. Auto — path picker (first run / no profile)

```
┌─────────────────────────────────────────────┐
│  Speaker Master                             │
│  Make this speaker sound better             │
│                                             │
│  Output: Sony ULT Field 1          [change] │
│                                             │
│  ┌─────────────────┐  ┌─────────────────┐   │
│  │    MEASURE      │  │     NARROW      │   │
│  │  Use a mic      │  │  No mic needed  │   │
│  │  Best for *this*│  │  Fast preset    │   │
│  │  speaker here   │  │  for this type  │   │
│  └─────────────────┘  └─────────────────┘   │
│                                             │
│  Safety limits always on · Hold Bypass=A/B  │
└─────────────────────────────────────────────┘
```

**Copy rules**

- Measure: “Listen with a mic, then fix this speaker in this place.”  
- Narrow: “Quick improve without a mic. Not the same as measuring.”  
- Never call Narrow “calibrated” or “any speaker world-class.”

**Entry variants**

| State | Screen |
|---|---|
| No profile for this output UID | Path picker above |
| Profile exists | Home “On for this speaker” + **Retry** + open Custom |
| Output UID changed | “New speaker detected” → path picker (old profile not auto-applied) |

---

## 2. Auto → Measure (guided one-session)

Toddler-simple primary path. Zero sliders by default.

### 2.1 Steps

| Step | User sees | User does | System |
|---|---|---|---|
| **M0 Permissions** | Why mic + system audio are needed (plain language) | Allow when macOS prompts | `NSMicrophone…` + audio capture TCC |
| **M1 Mic picker** | List of **available inputs** (built-in, USB measurement mic, Continuity/iPhone mic if present, etc.) | Select one | Remember last choice; never force USB-only |
| **M2 Place** | Diagram: Mac/mic toward speaker, quiet room, typical listen seat | Put gear there → Continue | — |
| **M3 Level** | Simple meter + “comfortable volume” | Set Mac/speaker volume | Abort if input clips hard |
| **M4 Sweep** | Big Play → progress (“Listening…”) | Wait; don’t talk | Play sweep / noise sequence out selected output |
| **M5 Build** | “Making filters…” | Wait | Cut-first correction within `safety-limits.md` |
| **M6 Done** | “Better sound is on” + **Hold to hear before** | Optional A/B; Done | Persist per output UID; limiter on |

### 2.2 Mic picker (detail)

```
Choose a microphone
○ MacBook Microphone          (built-in)
○ USB Mic — Umik-1            (if present)
○ iPhone Microphone           (if Continuity / available)
[ Refresh list ]

Tip: A measurement mic is more accurate. Built-in still works for a first pass.
```

- Empty list → explain; offer **Narrow** instead.  
- Denied mic → permission repair + Narrow escape hatch.  
- Switching mic mid-flow returns to M1 (do not keep stale calibration).

### 2.3 Failure states (Measure)

| Failure | UX |
|---|---|
| Mic permission denied | Fix Settings link + “Use Narrow instead” |
| System audio capture denied | Same pattern — cannot Measure meaningfully for system-wide claim |
| No mic devices | Narrow CTA |
| Noisy room / bad SNR | “Too noisy — try again or use Narrow” — **no hot guess curve** |
| Output disconnected mid-sweep | Abort to safe flat; prompt reconnect |
| BT drop | Abort; preserve previous good profile if any, else flat+limiter |
| Sweep cancelled | Flat+limiter; profile not overwritten |

### 2.4 Post-Measure home

```
┌─────────────────────────────────────────────┐
│  On for: Sony ULT Field 1                   │
│  Path: Measure · Saved today                │
│                                             │
│  [  Hold to hear before  ]                  │
│                                             │
│  [ Retry ]              [ Open Custom ]     │
└─────────────────────────────────────────────┘
```

**Retry** = explicit clear → back to path picker (Measure vs Narrow).  
**New speaker** (UID change) = invalidate; prompt re-run.

---

## 3. Auto → Narrow (no mic)

### 3.1 Steps

| Step | User sees | User does | System |
|---|---|---|---|
| **N1 Category / match** | Suggested match from device name + category cards (see `narrow-presets-sketch.md`) | Confirm or pick other | — |
| **N2 Apply once** | Short “Applying…” | Wait | Load curated curve under safety caps |
| **N3 Done** | Same home chrome as Measure, path = Narrow | A/B, Done | **Persist until Retry or new speaker** |

### 3.2 Persist / retry rules (locked)

| Event | Behavior |
|---|---|
| Same output UID returns / becomes default | Auto-apply stored Narrow (or Measure) profile |
| User taps **Retry** | Clear profile for this UID → path picker |
| Output UID changes | Do not reuse; prompt Measure or Narrow for new speaker |
| User had Measure, picks Narrow (or reverse) on Retry | Prompt: replace previous result? Never stack |
| Display name changes, UID same | Still reuse (`SpeakerIdentity` / `NarrowPersistencePolicy`) |

Paper confirmation line on N3:

> “Saved for this speaker. It stays on until you tap Retry or plug in a different speaker.”

### 3.3 Failure states (Narrow)

| Failure | UX |
|---|---|
| No category fits | “Generic Bluetooth-safe” + invite Measure later |
| Apply error | Flat+limiter; retry |
| Safety clamp on load of old preset | Silent re-clamp per safety sheet; optional one-line “Updated for current safety limits” |

---

## 4. Custom — progressive pro console

Same engine as Auto. Easy first layer; depth ≤2 reveals. Bar: SoundSource density without ACE scare; eqMac Expert depth without wall-of-knobs on open.

### 4.1 Layer map

| Layer | Name | Contents | Who |
|---|---|---|---|
| **L0** | Overview | Named intents (Balanced / Warmer / Clearer / Bass tamed), Auto result badge, Bypass, Undo/Reset, limiter status | Everyone |
| **L1** | Tone | Graphic or small set of musical bands + target hint; linked to safety caps | Curious |
| **L2** | Shape | Full parametric bands, Q, filter type; spectrum optional | Power |
| **L3** | Dynamics / safety | Limiter meter, ceiling readout (read-mostly), warnings — not a place to defeat Auto safety by default | Power |
| **L4** | Expert (optional later) | Advanced params, import/export — hidden until needed | Expert |

Open Custom on: **current Auto result** if present, else **safe default** (flat + limiter).

### 4.2 Paper — L0 Overview

```
┌─────────────────────────────────────────────┐
│  Custom                          [Bypass]   │
│  Based on: Measure · Sony ULT Field 1       │
│                                             │
│  Quick feel                                 │
│  ( ) Balanced  ( ) Warmer  ( ) Clearer      │
│  ( ) Bass tamed                             │
│                                             │
│  Limiter: On · within safe limits           │
│                                             │
│  [ Adjust tone → ]     [ Reset to Auto ]    │
│  [ Undo ]                                   │
└─────────────────────────────────────────────┘
```

### 4.3 Paper — L1 / L2 (reveal)

```
┌─────────────────────────────────────────────┐
│  ← Overview     Tone              [Bypass]  │
│  [======== EQ curve ========]               │
│   60   250   1k   4k   12k                  │
│                                             │
│  [ Show parametric bands → ]                │
│                                             │
│  ⚠ Boosts stop at safety limits             │
└─────────────────────────────────────────────┘
```

Hard requirements (visible):

- **Bypass** always  
- **Undo** / **Reset to Auto** (or safe default)  
- **Limiter** linked and labeled On  
- Attempt past caps → block or confirm per `safety-limits.md` §6 (v1: block)

### 4.4 Custom IA acceptance (paper-test)

| Test | Pass criteria |
|---|---|
| Non-expert | Can open Custom, try a named intent, Bypass, return — no manual |
| Power user | Reach parametric (L2) in ≤2 clicks/reveals from L0 |
| Safety | Cannot leave Auto-equivalent uncapped enhancer state without confirm (v1: cannot) |
| Auto sacred | One control returns to Auto home without losing “how do I re-run?” |

---

## 5. Permissions & system-wide (shared)

| Permission | When asked | If denied |
|---|---|---|
| Microphone | Measure M0/M1 | Narrow escape |
| System audio recording | First process / before Measure meaningful run | Explain system-wide needs it; Narrow may still apply presets once host works — if host blocked entirely, show blocked state honestly |
| Output access | Implicit via Core Audio | Chip shows wrong/missing device |

No virtual-device install screens (taps-first; no BlackHole).

---

## 6. A/B pattern

- **Hold to hear before** (preferred for Auto done + Custom)  
- Release = processed again  
- Reduced-motion / accessibility: toggle Before/After instead of hold  

---

## 7. Checklist mapping (phase-1)

- [x] Auto path picker Measure vs Narrow on paper  
- [x] Persist / retry / new-speaker clarified  
- [x] Measure mic picker among available inputs  
- [x] Measure guided steps + failure states  
- [x] Custom progressive layers vs SoundSource/eqMac bar  
- [x] Bypass / undo / limiter always considered  

*Related:* `docs/safety-limits.md`, `docs/narrow-presets-sketch.md`, `docs/product-brief.md`.
