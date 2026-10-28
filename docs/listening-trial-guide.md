# Listening / measure trial guide (phase-1)

**Project:** speaker-master  
**Purpose:** Prove (or disprove) audible upside of **measured correction** vs **flat** and vs **casual EQ** on the user’s real speakers — **before** any DSP product code.  
**Target Mac:** macOS **26.5.1** (25F80)  
**Speakers:** Sony **ULT Field 1** and the user’s **Alexa / Echo** (note exact Echo model in the log)  
**Date frozen:** 2026-10-28  
**Status:** Guide only — **user must run** the sessions; agents do not fake installs or results

This is the practical runbook for the open phase-1 gate: *at least one measured listening trial executed and documented*.

---

## 0. What “done” means

You are done when you have, for **each** of the two speakers (or a written skip with reason):

1. Heard **A** flat baseline  
2. Heard **B** casual EQ (eqMac or similar)  
3. Heard **C** a measured / Auto-style correction from an existing tool  
4. Written short notes: which was best, whether C beat A and B, any “worse” bands  
5. Stayed within the volume / safety rules in §2

No Speaker Master `.app` is required. Do **not** install experimental DSP builds for this gate.

---

## 1. Tool kit (realistic for macOS 26)

Pick **one path** from each column. Prefer free / trial tools you already trust.

### 1.1 Casual EQ (condition B)

| Tool | Role | Notes |
|---|---|---|
| **eqMac** (Free) | Best default for “casual system EQ” | Apply a mild “Bass / V-shape / loudness” style preset — **not** a full measure workflow. Keep boosts modest (see §2). |
| **SoundSource** (if already owned) | Alternate host for a simple graphic / AU EQ | Use only a gentle preset; this trial is not about AU shopping. |
| **Boom / Boom 3D** | Optional negative control | Only if you already have it — useful to feel “enhancer” vs honest correction. Keep volume low. |

### 1.2 Measured / Auto-style correction (condition C)

Choose **one** primary path. Fallbacks listed if install/trial fails.

| Priority | Tool | How it helps on Mac | Caveat |
|---|---|---|---|
| **1 — preferred consumer** | **Spectra** (trial if available) | Closest product thesis: measure + system EQ on modern Mac | Trial limits / install friction — note anything that blocks you |
| **2 — bass Auto** | **Reflect** | Fast cut-first bass Auto + A/B | Bass-region only — still valid evidence for “Auto helps” on small BT boxes |
| **3 — gold measure → export** | **REW** (Room EQ Wizard, freeware) | Measure FR with a mic; design limited PEQ (cut-first) | REW does **not** apply system-wide alone — export filters into eqMac Pro PEQ / SoundSource AU / Camilla stack if you already have one |
| **4 — phone measure** | **HouseCurve** (iPhone/iPad) | Guided sweep UX; export PEQ/FIR | Official Mac Catalyst unsupported — measure on phone, apply filters on Mac host if you can; otherwise use Spectra/Reflect/REW |

**Mic for Measure paths:** use whatever you have and can select — MacBook built-in, Continuity iPhone mic (if the tool supports it), or USB measurement mic. Built-in is **good enough for this gate** (audible upside check), not a lab claim.

**Skip BlackHole + CamillaDSP** unless you already run that stack. Do not invent a GPL virtual-device install just for phase-1.

### 1.3 Playback material (same for A/B/C)

Use **3 short clips** you know well, ~20–40 s each, same playlist every condition:

1. **Bass / kick** — electronic or hip-hop with clear low end  
2. **Voice** — podcast or well-recorded vocal  
3. **Busy mix** — dense pop/rock (masks / mud test)

Keep Spotify/YouTube **volume normalization** consistent (or off) across the whole session.

---

## 2. Safety (mandatory)

Align with `docs/safety-limits.md`. Trial tools may not enforce our caps — **you** enforce them.

| Rule | Practice |
|---|---|
| **Start quiet** | System volume ~30–40%; speaker volume mid. Raise only after each condition sounds clean. |
| **Never max** | Do not run sweeps or EQ at device max. Sweeps at a **comfortable conversation-plus** level. |
| **Boost discipline** | For casual EQ and any manual PEQ: prefer cuts; broadband lift ≤ ~+3 dB; bass boost ≤ ~+4 dB; single band ≤ ~+6 dB. If a tool suggests hotter curves, dial them down or reject. |
| **Ears first** | Stop if harsh, distorted, or fatiguing. Distortion ≠ “more bass.” |
| **One EQ host** | Disable other system EQ / enhancers so A/B/C are not stacked. |
| **Hearing break** | ≥2 minutes quiet between speakers; stop the session if ears feel tired. |

Hearing damage and blown small drivers are not theoretical — treat ULT Field 1 / Echo as fragile BT boxes.

---

## 3. Session protocol (per speaker)

Do Sony ULT Field 1 first, then Alexa/Echo. Same room position for all three conditions on that speaker.

### 3.1 Setup

1. Connect **only** the speaker under test as Mac default output (Bluetooth or whatever you normally use).  
2. Quit / bypass Boom, unused EQ apps, spatial “enhance” toggles.  
3. Note in the log: date, room (living room / desk), approximate distance, Echo **exact model** if known, mic used (if measuring).  
4. Set a **reference volume** once for condition A; match loudness by ear for B and C (correction often changes perceived loudness — level-match before judging).

### 3.2 Condition A — Flat baseline

1. All EQ / correction **off**.  
2. Play the three clips.  
3. Log: boom / mud / thin / harsh / good enough?

### 3.3 Condition B — Casual EQ

1. Enable eqMac (or SoundSource) with a **mild** casual curve (e.g. slight bass shelf + tiny presence — not max presets).  
2. Level-match to A.  
3. Same three clips.  
4. Log: better than A? worse? where (bass / voice / fatigue)?

### 3.4 Condition C — Measured correction

Follow **one** of:

**Path Spectra / Reflect**

1. Run the app’s guided measure / Auto for this output.  
2. Use the app’s **A/B or bypass** if present — hold dry vs corrected.  
3. Level-match. Play the three clips.  
4. Log vs A and vs B.

**Path REW → host EQ**

1. Place mic near listening position (or on Mac lid if built-in).  
2. Measure with a short sweep at safe level.  
3. Design a **cut-first** PEQ (≤4–6 bands); stay under §2 boost caps; do not chase deep nulls with big boosts.  
4. Load filters into eqMac PEQ / AU host. Bypass check.  
5. Log vs A and vs B.

**Path HouseCurve (phone) → Mac filters**

1. Measure with HouseCurve on iPhone near the seat.  
2. Export limited PEQ; import into Mac host if possible.  
3. If you cannot apply on Mac, still log HouseCurve’s own playback A/B on the phone **only as secondary evidence**, and mark Mac system-wide C as **blocked** with reason.

### 3.5 Quick forced A/B (recommended)

For the winning clip of condition C:

- 10 s corrected → 10 s flat → 10 s corrected  
- Then 10 s casual EQ → 10 s measured  

Write which you prefer **before** looking at graphs.

---

## 4. How to note results

Copy this template into a local note, PR comment, or `docs/listening-trial-results.md` (create when you have data — **do not** invent results).

```text
# Listening trial log — speaker-master phase-1

Date:
Mac / macOS:
Room / distance:
Mic (if any):

## Speaker 1 — Sony ULT Field 1
Output name in Sound settings:
Tools used (B / C):

A flat: 
B casual: 
C measured: 
Winner (A/B/C) + why:
Audible upside of C vs A? (yes/no/unclear)
Audible upside of C vs B? (yes/no/unclear)
Would pay/build for this gap? (yes/no/maybe)

## Speaker 2 — Alexa / Echo
Exact model:
Output name:
Tools used (B / C):

A / B / C notes:
Winner + why:
C vs A / C vs B:
Would pay/build for this gap?

## Decision for phase-1 gate
[ ] Measured upside clear on ≥1 speaker → keep dual-mode bet
[ ] Upside weak / only casual EQ matters → revisit product bet before DSP
[ ] Blocked (tool/mic/time) → list blocker; stay in phase-1 research

Safety: volumes kept moderate? Y/N
Stacked EQ avoided? Y/N
```

**Honesty rules for notes:** subjective is fine; do not claim “calibrated flat” from a laptop mic; do not treat Reflect bass-only as full-band world-class proof — it still counts as Auto-style evidence.

---

## 5. Suggested time box

| Block | Time |
|---|---|
| Install / trial signup / permissions | 15–30 min (once) |
| Sony session A→B→C | 25–40 min |
| Echo session A→B→C | 25–40 min |
| Write log + decision checkboxes | 10 min |

Total: roughly **one focused evening**. Stopping after one speaker with a clear C-vs-A result is better than a rushed incomplete pair — mark the other speaker deferred.

---

## 6. Gate mapping

| Phase-1 checklist item | This doc |
|---|---|
| Measured listening trial executed on user’s speakers | §3 + §4 log (user-run) |
| Audible upside vs flat / casual EQ documented | §4 template |
| Competitive dual-mode gap still open | See `docs/competitive-gap-note.md` (docs refresh); listening may still force a pivot |

**Still required after this guide ships:** the user actually runs §3–§4. Shipping the guide alone does **not** clear the listening gate.

---

## 7. Explicit non-goals for this trial

- No Speaker Master DSP / `.app` install  
- No BlackHole install “just because”  
- No dual-BT sync tests (out of product scope)  
- No claiming lab-grade calibration from built-in mic  
- No Boom-max volume “wow” demos

*End of listening trial guide.*
