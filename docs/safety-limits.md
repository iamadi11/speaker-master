# Safety limits sheet (frozen for phase-1 → DSP)

**Project:** speaker-master  
**Status:** Written policy — freeze before any production DSP  
**Applies to:** Auto (Measure + Narrow) and Custom  
**Host:** MacBook, system-wide Core Audio process taps (target macOS 26.5.1)  
**Date:** 2026-10-28

This sheet is the non-negotiable ceiling for hearing safety, speaker protection, and anti–Boom-class enhancer behavior. Phase-2 DSP must implement these caps; Custom may *request* more power only behind explicit confirm (see §6).

---

## 1. Design principles

| Principle | Rule |
|---|---|
| **Safe by default** | Auto never ships uncapped boost or silent “enhancer” gain |
| **Cut-first** | Prefer reducing peaks / problem bands over broadband lift |
| **Limiter always on for Auto** | Soft peak limiter cannot be disabled on Auto paths |
| **Same ceiling for Custom** | Custom inherits Auto caps; expert overrides need confirm |
| **Honest claims** | Measure owns calibration language; Narrow never claims mic correction |
| **No ultrasonics** | No intentional content or sweeps above the audible product band used for correction |

---

## 2. Numeric caps (v1 freeze)

Values are **engineering defaults** for small Bluetooth / portable speakers (Sony ULT-class, Echo-class). Revisit only with listening evidence + written ADR — not ad-hoc in UI.

| Limit | Value | Notes |
|---|---|---|
| **Broadband / loudness-style boost** | **≤ +3 dB** | Any wideband “make louder / enhance” style lift |
| **Per-band boost (PEQ / graphic)** | **≤ +6 dB** | Single band or overlapping constructive boosts counted against this ceiling at the worst frequency |
| **Bass-region boost (≤ ~120 Hz)** | **≤ +4 dB** | Stricter than mid/treble — small drivers clip / bottom out easily |
| **Per-band cut** | **No hard floor** (practical UI ≤ −18 dB) | Cuts are preferred; extreme cuts OK if user-driven in Custom |
| **Total constructive gain at any Hz** | **≤ +6 dB** | Sum of overlapping filters + loudness must not exceed |
| **Auto target correction strength** | Prefer cuts; boosts only to fill measured dips within caps above | Measure path: do not chase every null |
| **True-peak / sample peak ceiling** | Soft limit toward **−1.0 dBTP** (engine target) | Prevent DAC / BT encoder overload |
| **Limiter release / character** | Transparent soft knee; no pumping as default | Auto uses fixed safe preset; Custom may tune *within* ceiling |
| **Makeup after limiting** | **0 dB** default; **≤ +1 dB** only if still under broadband cap | Avoid “limiter then crank” |
| **Latency / processing** | Keep correction IIR/PEQ-first; long FIR only if latency UX is explicit | Not a gain rule — avoids “fix” via heavy wet FX |

### 2.1 Measure-specific

| Rule | Value / behavior |
|---|---|
| Sweep level | Comfortable listening level; never force max device volume |
| Mic gain guidance | Prefer clean signal without clipping the input meter |
| Correction band | Focus useful audible band for BT boxes (roughly ~60 Hz–16 kHz); do not invent ultrasonic energy |
| Bass priority | For small portables, prioritize taming boom / one-note bass over deep extension |
| Failure → safe | Noisy room / bad mic / abort → **flat + limiter**, never a half-baked hot curve |

### 2.2 Narrow-specific

| Rule | Value / behavior |
|---|---|
| Preset max boost | Same global caps (§2) — curated curves must be authored under the ceiling |
| No “ULT / Bass Booster” mode | Named intents may warm/cut; never uncapped enhancer |
| Persist does not relax caps | Stored Narrow profile still runs through limiter + caps on apply |

---

## 3. Always-on safety behavior

1. **Soft limiter** on the processed path whenever Auto is active.  
2. **Clip / near-clip warning** in UI if input to the limiter is chronically hot (user should lower system or speaker volume — app does not silently keep stacking gain).  
3. **Hearing / loudness note** on first Auto run and when Custom tries to raise broadband boost: short plain-language warning (not legal theater).  
4. **Bypass** always available (Custom and post-Auto home) — instant dry path.  
5. **Undo / Reset to safe** restores last Auto result or flat+limiter — never an empty unprotected chain.

---

## 4. Anti-patterns (explicitly forbidden)

| Anti-pattern | Why banned |
|---|---|
| Boom-class uncapped bass / “enhancer” | Distortion, damage lore, trust collapse |
| Silent ultrasonic / inaudible “air” boosts | No product benefit; risk of HF energy into bad transducers |
| Mute-until-reboot / stuck virtual-device traps | Prefer taps; never leave the Mac in a broken default-output state |
| Auto that maxes volume then EQ | Volume stays user’s; we process within caps |
| Disabling limiter on Auto | Non-negotiable for Auto |
| Marketing “any speaker calibrated” for Narrow | Honesty rule — Measure only |
| Custom default layout that starts past safety caps | Open on Auto result or safe default |

---

## 5. Warnings & user-visible copy (intent)

Keep short; toddler-Auto path stays calm.

| Moment | Message intent |
|---|---|
| First Auto | Processing stays within safe boost limits; hold A/B to compare |
| Chronic limiting | Turn down Mac or speaker volume a bit — sound is hitting the safety ceiling |
| Custom extreme boost attempt | This goes past safe Auto limits — confirm to proceed (if expert override exists) |
| Mic denied / no mic (Measure) | Offer Narrow or fix permission — do not invent a hot guess curve |

Exact strings live in UX copy later; intent is frozen here.

---

## 6. Custom vs Auto inheritance

| Surface | Limiter | Boost caps | Expert override |
|---|---|---|---|
| **Auto Measure** | On, not user-off | Hard caps §2 | None |
| **Auto Narrow** | On, not user-off | Hard caps §2 | None |
| **Custom (default)** | On, linked, visible | Same hard caps | None by default |
| **Custom (expert, if ever)** | Remains on unless second confirm | May raise **per-band** only after confirm; broadband still ≤ +3 dB unless third confirm | Confirm copy must mention hearing / speaker risk |

v1 recommendation: **ship Custom without raising caps above §2**. Add expert override only if listening trials prove need — and only behind confirm.

---

## 7. Per-output profile interaction

Stored profiles (Measure or Narrow) always re-apply **through** current safety engine:

- Changing caps in a future ADR re-clamps old profiles on load.  
- Switching speaker (new Core Audio output UID) does not carry the old curve blindly — see `paper-ux-flows.md` / Narrow persistence.  
- Conflict Measure ↔ Narrow: prompt; never stack both gains.

---

## 8. Freeze & change control

| Item | Rule |
|---|---|
| This document | **Frozen** for phase-1 gate “written safety limits sheet” |
| Numeric changes | Require ADR under `docs/adr/` + listening note |
| DSP PR gate | Reject PRs that introduce Auto boost above §2 or Auto without limiter |
| Install claim | No `.app` yet — this sheet does **not** imply shipped DSP |

---

## 9. Checklist mapping (phase-1 §2.5)

- [x] Numeric/policy caps drafted  
- [x] Hearing / clipping warnings intent  
- [x] Anti-pattern list (Boom / mute lore / ultrasonics)  
- [x] Custom inherits ceiling; expert override policy stated  
- [x] Sheet frozen before production DSP  

*Related:* `docs/product-brief.md`, `docs/paper-ux-flows.md`, `docs/narrow-presets-sketch.md`, `GLOSSARY.md` (Safety sheet).
