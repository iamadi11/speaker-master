# Per-screen states — Speaker Master

Canonical companion to `docs/paper-ux-flows.md`. Agents use this when editing copy or layout.

Legend: **Job** = user job · **Next** = one primary next action · **Tone** = copy voice.

---

## 1. First launch / Auto path picker

| | |
|---|---|
| **Job** | Understand Measure vs Narrow in one glance; pick one |
| **Next** | Tap Measure **or** Narrow |
| **Tone** | Toddler-simple; two quiet choices; no settings dump |
| **Success** | User leaves into Measure or Narrow with clear intent |
| **Empty** | No profile for this output — show picker (not a blank “home”) |
| **Fail** | — |
| **Denied** | System EQ may need permission — show honest strip, quieter than the two paths |

Copy anchors:

- Title: “Make this speaker sound better”
- Measure subtitle: mic · best for this speaker here
- Narrow subtitle: no mic · fast · **not calibrated**
- Optional: “No EQ yet for this speaker” when first run / cleared

Headphone warning only when output name looks like headphones.

---

## 2. Permissions — Microphone (Measure)

| | |
|---|---|
| **Job** | Grant mic so Measure can record |
| **Next** | Open Microphone settings (or Allow when prompted) |
| **Tone** | Plain why + named Privacy pane |
| **Success** | Mic list fills; Play & measure enables |
| **Empty** | Authorized but no devices → plug in / Refresh / Narrow escape |
| **Fail** | Ask again / Refresh after Settings |
| **Denied** | Banner + Open Microphone settings + **Use Narrow instead** |

Never block the whole app on mic denial — Narrow must remain reachable.

---

## 3. Permissions — Screen & System Audio

| | |
|---|---|
| **Job** | Understand whether Spotify/other apps are covered |
| **Next** | Open Privacy Settings or Retry system EQ |
| **Tone** | Honest phase language from `SystemEQEmptyStateCopy` |
| **Success** | “System-wide EQ active” only when tap is truly active |
| **Empty / Denied / Fail** | Match empty-state table; never fake active |

In-app audition may still work when system-wide is blocked — say so without claiming system-wide.

---

## 4. Measure flow

| | |
|---|---|
| **Job** | Complete one take: select mic → place → record → analyze → apply |
| **Next** | Play & measure (when mic ready) |
| **Tone** | Linear steps; big primary; honesty about first-pass analyzer |
| **Success** | Land on Auto home · Path: Measure · Saved for this speaker |
| **Empty** | No mics → Narrow CTA |
| **Fail / bad take** | Honest note; **nothing invented applied**; prior good profile kept |
| **Denied** | Mic banner + Narrow escape |

Phase labels on the primary button:

| Phase | Button / status |
|---|---|
| Idle ready | Play & measure |
| Recording | Listening… |
| Analyzing | Analyzing… |
| Applied | (navigate home) |
| Refused | Stay on Measure with recovery copy |

Guidance always visible: place mic toward speaker, quiet room, comfortable volume — never force max. Escape: Use Narrow instead. Back → path picker.

---

## 5. Narrow flow

| | |
|---|---|
| **Job** | Fast improve without a mic |
| **Next** | Tap a preset (Suggested emphasized) |
| **Tone** | Fast / not calibrated; invite Measure for better match |
| **Success** | Auto home · Path: Narrow · {name} · **stays until Retry or different speaker** |
| **Empty** | Categories always present from catalog |
| **Fail** | Flat+limiter; status honesty |
| **Denied** | N/A for mic; System EQ still honest on home |

---

## 6. Auto home (profile applied)

| | |
|---|---|
| **Job** | Trust EQ is on for this speaker; A/B; optionally refine or retry |
| **Next** | Hold Bypass to hear before (toolbar / ⌘B) — trust signal |
| **Tone** | Sparse: title, path, persist line; Bypass primary in chrome |
| **Success** | “On for {speaker}” + path + persist honesty |
| **Empty** | Should not appear — empty → path picker |
| **Fail** | System EQ panel recovery; curve still local |
| **Denied** | Same |

Required lines:

- Path: Measure · Saved for this speaker **or** Path: Narrow · {name}
- Persist: “Stays on until Retry or a different speaker.”
- Controls: Bypass (chrome) · Retry (clear → picker) · Open Custom (secondary/prominent but not louder than trust)

Audition = optional proof, not the hero CTA.

---

## 7. Custom (progressive disclosure)

| | |
|---|---|
| **Job** | Refine the same engine without losing Auto home |
| **Next** | Soft intent **or** nudge a band; Advanced off by default |
| **Tone** | Quiet power; based-on as caption; limiter as footnote |
| **Success** | Edits apply under safety caps; Undo / Reset to Auto work |
| **Empty** | Safe default if no Auto result — say so |
| **Fail** | Caps block unsafe boosts; show headroom near ceiling |
| **Denied** | System EQ honesty unchanged |

Orientation: based-on label + easy return to Auto (Mode ⌘1). Custom never replaces sacred Auto home after Measure/Narrow.

Intents: soft chips (hairline + soft fill). Not solid teal bricks.

---

## 8. Mode switch Auto ↔ Custom

| | |
|---|---|
| **Job** | Move between sacred Auto home and refine without disorientation |
| **Next** | Segmented Mode (toolbar) / ⌘1 / ⌘2 |
| **Tone** | Status strip or based-on reminds what’s on |
| **Success** | Auto tab shows home if profile exists; Custom shows based-on |
| **Fail** | Never wipe profile solely because user opened Custom |

---

## 9. Bypass / recovery / new speaker

| Event | UX |
|---|---|
| Bypass hold / toggle | Hear before; release = processed again; reduced-motion = toggle |
| Retry | Clear profile for this UID → path picker |
| New output UID | Do not reuse; path picker; old profile not auto-applied |
| Measure cancel / BT drop | Abort; keep prior good profile if any |
| System EQ failed | Honest panel + Retry / Open Privacy Settings |
