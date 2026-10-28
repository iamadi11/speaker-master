# Auto Measure pipeline — record → analyze → apply (best safe EQ)

**Project:** speaker-master  
**Task:** SM-18  
**Status:** Design locked; product Measure path implemented in-app (SM-19)  
**Date:** 2026-10-28  
**Audience:** Product + agents — Measure pipeline contract

## Locked product algorithm (Auto → Measure)

When the user chooses **Auto → Measure**, the app does this — not a side helper, the **core Measure path**:

1. **Temporarily record** audio from a **user-selected** available mic input (built-in, USB measurement mic, Continuity/iPhone mic if present, …).
2. **Analyze** that recording (stimulus was played to the connected speaker during / around the capture).
3. **Implement / apply** the **best audio configuration** in **Auto EQ mode** — cut-first correction within `docs/safety-limits.md`, soft limiter on, persist per output.

Agents cannot hear speakers. They may later **reuse the same record → analyze → (optional metrics) path** for verification reports. **Applying** EQ for the user is the **product app’s** job. **Human taste** still gates the Phase-2 “world-class” claim and SM-12 listening evidence — metrics never auto-declare world-class.

Related UX steps: `docs/paper-ux-flows.md` §2 (M0–M6). Safety ceiling: `docs/safety-limits.md`.

---

## 0. Verdict (read this first)

| Question | Answer |
|---|---|
| What is Auto Measure? | **Record (selected mic) → analyze → apply best safe Auto EQ** on the current speaker/output. |
| Can an agent “hear” the room? | **No.** Only a local Mac process can capture. |
| Mic vs process tap? | **Mic** = room/speaker measurement input. **Process tap** = system-wide EQ **host** (playback path), not the acoustic measure of the room. |
| Can metrics alone claim “world-class / sounds better”? | **No.** Metrics gate safety + score distance-to-target; **human listening** gates taste and Phase-2 world-class. |
| Does this clear SM-12 / Phase-2 DSP go? | **No.** Complements SM-12; does not replace it. |
| Partial Phase-2 unblock? | **Yes** — pipeline contract + optional analyzer spike; full correction solver still gated. |

---

## 1. Pipeline detail (product)

```
User: Auto → Measure
        │
        ▼
┌───────────────────┐
│ 1. RECORD         │  Pick mic → place → level → play stimulus
│    (temporary)    │  Capture room sound via selected input
└─────────┬─────────┘
          ▼
┌───────────────────┐
│ 2. ANALYZE        │  Estimate response vs target; score bands;
│                   │  reject noisy / clipped takes
└─────────┬─────────┘
          ▼
┌───────────────────┐
│ 3. APPLY (Auto EQ)│  Build cut-first filters within safety caps
│    best config    │  Soft limiter on → persist per output UID
└─────────┬─────────┘
          ▼
     Hold-to-A/B → Done / Retry / Custom
```

### 1.1 Step 1 — Temporary record

| Property | Intent |
|---|---|
| Input | **User-selected** mic among available inputs (never force one path) |
| Stimulus | Short sweep / noise / guided sequence out the **current** speaker/output |
| Duration | Session-bounded (sweep length + short pads); not always-on recording |
| Storage | Temp only (`temporaryDirectory` / `mkstemp`); **delete** after analyze (success or fail) |
| Volume | Comfortable listening level; never force device max (`safety-limits.md` Measure rules) |
| Privacy | Local only; no upload of captures in v1 intent |

### 1.2 Step 2 — Analyze

| Concern | Intent |
|---|---|
| Goal | Infer how this speaker+room+mic diverge from the Auto target; propose a **limited** correction |
| Objective scores | Spectral distance to target, band energy, crest, clip/near-clip, SNR / noise floor |
| Failure → safe | Noisy room, bad mic, abort → **do not apply** a hot guess; stay **flat + limiter** (or keep last good profile per UX) |
| Honesty | Built-in mic is OK for first pass; do not claim lab calibration |

Exact solver (PEQ count, smoothing, bass priority for small BT boxes) is Phase-2 DSP — design here only locks the **stage order** and safety envelope.

### 1.3 Step 3 — Apply best Auto EQ configuration

| Rule | Intent |
|---|---|
| **Best** means | Best **within safety caps** and cut-first policy — not max loudness / Boom-class enhance |
| Caps | Broadband ≤ +3 dB; per-band ≤ +6 dB; bass-region ≤ +4 dB; total constructive ≤ +6 dB; limiter on (`safety-limits.md`) |
| Host | Applied on the **system-wide** process-tap (or product host) path so Spotify/YouTube/etc. hear it |
| Persist | Per Core Audio output UID until Retry / new speaker (same as product lock) |
| User control | Hold-to-A/B, Bypass, Retry; Custom can refine the same engine later |
| Not “best” if unsafe | Clip risk, over-boost, or failed analyze → refuse apply |

**“Implements the best audio configuration”** is therefore: compute the safest cut-first correction that most reduces distance to the Auto target, then **turn it on** for that speaker. It is **not** unconstrained optimization and **not** silent enhancer gain.

---

## 2. Feasibility on Mac (permissions, TCC, tap vs mic)

### 2.1 Two different signals (do not confuse)

| Capture | What it hears | Role |
|---|---|---|
| **Microphone** | **Room sound** after speaker + room + mic | **Measure input** (steps 1–2) |
| **Process tap** | Digital mix **before** the physical speaker | **EQ host / playback** (step 3 apply); optional stimulus reference — **not** the acoustic measure alone |

Product Measure needs the **mic** path for correction credibility. Process taps remain how system-wide Auto EQ is heard after apply.

### 2.2 TCC / Info.plist

| Capability | Usage key | Settings |
|---|---|---|
| Microphone | `NSMicrophoneUsageDescription` | Privacy & Security → **Microphone** |
| System audio (tap host) | `NSAudioCaptureUsageDescription` | Privacy & Security → **Screen & System Audio Recording** → System Audio Recording Only |

Future `.app` embeds both. Missing mic string → often **no prompt**, silent fail.

### 2.3 Agents vs product app

| Runner | Record | Analyze | Apply Auto EQ |
|---|---|---|---|
| **Product `.app` (user)** | Yes (after Allow) | Yes | **Yes — primary** |
| **CLI spike on user’s Mac** | Maybe (TCC via Terminal/Cursor host) | Yes (fixtures or live) | Optional **dry-run** only in early spike; product apply stays in app |
| **Cloud agent VM** | **No** user’s mic/speakers | N/A | **No** |

**Hard rules:**

- Pipeline runs **on the user’s Mac**.
- Cloud agents may **orchestrate** a local tool and read a metrics JSON; they must not invent hearing or listening-trial results.
- launchd / daemon-reparented processes often get **mic silence** — out of scope for Measure.
- **Needs verification** on this Mac (26.5.1): TCC attribution when Cursor’s shell launches a signed CLI — document after first spike; do not invent.

---

## 3. Objective “decide” vs human taste

### 3.1 What the product may decide automatically (inside Apply)

Within one Measure session, after a **good** take, the app **may** choose and **apply** the filter set that:

- Minimizes spectral distance to the Auto target (banded ~60 Hz–16 kHz for BT boxes), **and**
- Stays inside safety caps + limiter, **and**
- Prefers cuts; does not chase deep nulls with big boosts.

That is the meaning of **best audio configuration in Auto EQ mode**.

### 3.2 What still needs a human

| Judgment | Why |
|---|---|
| Preference / fatigue / “musical” | Target ≠ taste |
| SM-12 A/B/C winner | Ear-first gate by design |
| Phase-2 **world-class** claim | User listening + preferences bar — not score max |
| Shipping / keeping a controversial curve | Human go |

### 3.3 Agent verification reuse (same path, different intent)

Agents (or CI) can reuse **record → analyze** and emit a report for verification:

```json
{
  "schema": "speaker-master.measure-report.v0",
  "ok": true,
  "safety": { "clipping": false, "peakDbFS": -6.2, "withinBoostCaps": true },
  "compare": {
    "spectralDistanceBefore": 4.8,
    "spectralDistanceAfter": 2.1,
    "improvedDistance": true
  },
  "recommendation": "metrics_improved_await_human_listen",
  "productApply": "app_owned",
  "worldClassClaim": false
}
```

| Field intent | Rule |
|---|---|
| `recommendation` | Metrics aid only (`metrics_improved_await_human_listen` / `metrics_worse_or_unsafe` / `inconclusive_noisy_or_bad_take` / `blocked_permission`) |
| `productApply` | Always `app_owned` for real Auto EQ — agents do not merge DSP from chat |
| `worldClassClaim` | Always `false` from metrics alone |

Product Apply (step 3) is **not** gated on an agent JSON file in the toddler path — the app applies after successful analyze. Agents use the report to **verify**, not to override human taste or SM-12.

---

## 4. Minimal spike architecture (optional, design-first)

**This PR is docs-only.** A later small spike may prove local mic capture + analyzer on fixtures.

| Piece | Role |
|---|---|
| Executable `sm-measure` (optional) | `capture` / `analyze` → JSON; scrub temps |
| `MeasureRecorder` | Short mic capture to temp URL |
| `MeasureAnalyzer` | Band energy / crest / clip / distance (Accelerate/vDSP OK) |
| `MeasureReport` | Codable; `worldClassClaim: false` |
| Tests | Fixture WAVs only in CI (no live mic) |

Playback of stimulus can stay external (`afplay`) for the first spike. Full sweep UX + filter solver + tap host = product Phase-2 after gates.

**Spike non-goals:** production Auto merge from agent chat, BlackHole, always-on recorder, lab FR claims from laptop mic.

---

## 5. Safety (mandatory)

Align with `docs/safety-limits.md`.

| Rule | Practice |
|---|---|
| Temp files deleted | Always after analyze; scrub on error; never commit captures |
| Volume | Comfortable sweeps; never instruct max volume |
| Apply within caps | Best config **means** best under the ceiling + cut-first + limiter |
| Failure → safe | Bad take → no new hot curve |
| No ultrasonics | Stimulus in audible product band |
| Privacy | Local captures only |
| World-class | Human listening still required; metrics ≠ marketing claim |
| Agent honesty | No fabricated reports or fake SM-12 results |

---

## 6. Interaction with SM-12 (listening trial)

| | SM-12 listening trial | This Auto Measure pipeline |
|---|---|---|
| **Purpose** | Prove **audible** upside with **existing** tools before DSP go | Define how **our** app will Measure later |
| **Who** | **User** ears + Spectra/Reflect/REW/… | Future product app (+ optional agent metrics reuse) |
| **Clears Phase-1 gate?** | **Yes** when executed + logged | **No** (design only) |
| **Apply EQ?** | Via third-party hosts for the trial | Product step 3 when built |

**Sequencing:** SM-12 stays open until the user runs `docs/listening-trial-guide.md`. This doc does not complete SM-12. SM-17 (Phase-2 DSP go) still needs listening evidence + user go. Optional later: attach `sm-measure` metrics beside a repeat A/B — ear winner still owns the gate.

---

## 7. Phase-2 partial unblock checklist

| Item | Status |
|---|---|
| Auto Measure = record → analyze → apply best safe EQ | **Locked in this doc** |
| Mic selectable; tap = host not room measure | Done |
| Safety caps on Apply | Done |
| Agent reuse = metrics only; world-class needs human | Done |
| SM-12 relationship | Done |
| `sm-measure` CLI / analyzer spike | Optional; in-app Measure covers product path |
| In-app Measure (select mic → record → analyze → apply + persist) | **Shipped in product app (SM-19)** — simplified band analyzer, not lab FR |
| System-wide tap host after Apply | **Shipped (SM-21)** when TCC permits |
| Full “world-class” / unrestricted DSP go | Still gated (SM-12 listening + SM-17) |

**Partial unblock:** Yes — product Measure stages follow this contract. Full “world-class” claim remains behind listening trial + human taste.

---

## 8. Related docs

| Doc | Relation |
|---|---|
| `docs/product-brief.md` | Locked modes; Measure pipeline one-liner |
| `docs/paper-ux-flows.md` | M0–M6 UI for this pipeline |
| `docs/safety-limits.md` | Caps on Apply |
| `docs/listening-trial-guide.md` | SM-12 human protocol |
| `docs/phase-1-checklist.md` | Gate checkboxes |

*End of Auto Measure pipeline design.*
