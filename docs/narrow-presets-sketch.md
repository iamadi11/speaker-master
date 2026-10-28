# Narrow presets sketch (day-one content)

**Project:** speaker-master  
**Status:** Content sketch — not shipped DSP curves  
**Date:** 2026-10-28  
**Honesty:** Narrow ≠ Measure. Marketing must never say “calibrated” for Narrow.

Day-one Narrow is: **device-name / output-name match**, **category picker**, and a few **BT-safe curated curves** under `docs/safety-limits.md`. Not a fake “any speaker measured” database.

---

## 1. What Narrow can honestly ship

| Mechanism | Day one? | Notes |
|---|---|---|
| Match Core Audio **device / output name** to a known template | Yes | Sony ULT*, Echo/Alexa*, generic BT |
| User **category** pick (“Bluetooth box”, “Echo-class”, …) | Yes | When name match weak or wrong |
| Photo / big-tile picker | Yes (UX) | Same categories; visuals later |
| AutoEQ-style headphone DB applied to speakers | **No** | Wrong domain; do not claim |
| Full speaker measurement DB | **No** | That’s Measure territory |
| Uncapped “bass enhancer” intents | **No** | Banned by safety sheet |

---

## 2. Identity & storage (with profiles)

Stored with each Narrow apply (conceptually):

| Field | Example |
|---|---|
| `outputUID` | Core Audio UID (primary key) |
| `displayName` | “ULT Field 1” |
| `autoPath` | `narrow` |
| `presetId` | `sony-ult-portable` |
| `categoryId` | `bt-portable` |
| `safetyRevision` | matches safety sheet version |
| `appliedAt` | timestamp |

Reuse when `outputUID` matches (`NarrowPersistencePolicy`). Retry clears. New UID → re-pick.

---

## 3. Category set (v1 sketch)

Keep the list short. Toddler Auto path: big tiles, one tap.

| ID | Tile label | When to offer | Intent of curve (words only) |
|---|---|---|---|
| `bt-portable` | Bluetooth box | Default unknown BT speaker | Tame one-note boom; slight clarity; minimal boost |
| `echo-class` | Echo / Alexa | Name contains Echo/Alexa/Amazon | Soften harsh top; control mid-bass thump |
| `sony-ult-portable` | Sony portable / ULT | Name match ULT Field / XB-class portable | Respect small driver; cut mud; light presence — **not** Sony ULT button clone |
| `desktop-nearfield` | Desk speaker | User picks / “Computer speakers” | Mild desk-boundary bass cut; even mids |
| `generic-safe` | Just make it safer | Fallback | Almost flat + gentle harshness cut + limiter — never embarrassing |

**Priority when suggesting**

1. Strong name match → preselect matching preset tile  
2. Else category guess from keywords (Bluetooth, AirPods≠speaker — exclude headphone-looking outputs if detectable)  
3. Else show all tiles with **Bluetooth box** highlighted  

---

## 4. Name-match heuristics (draft)

| Pattern (case-insensitive contains) | Suggest |
|---|---|
| `ULT Field`, `ULT FIELD`, `SRS-ULT` | `sony-ult-portable` |
| `Echo`, `Alexa`, `Amazon` | `echo-class` |
| `Bluetooth`, `BT`, unknown sink | `bt-portable` |
| Built-in Mac speakers | Optional later — out of “connected speaker” hero path for now |
| Headphones / AirPods in name | **Do not** auto-Narrow as speaker; warn “this looks like headphones” |

Exact Echo model still open (phase-1) — when known, add a row; until then `echo-class` is enough.

---

## 5. Curve authoring rules (before any DSP numbers)

All curated Narrow curves must:

1. Obey **safety-limits.md** (bass boost ≤ +4 dB, per-band ≤ +6 dB, broadband ≤ +3 dB, limiter on).  
2. Prefer **cuts** (mud, harshness) over lift.  
3. Survive A/B vs flat on at least one real BT box without “Boom” smear.  
4. Include a one-line **honest description** shown in UI.  
5. Ship `generic-safe` that never sounds broken on wrong category.

Numeric PEQ tables: **deferred** until listening trial — this sketch freezes *taxonomy + honesty*, not filter math.

---

## 6. Marketing / UI copy (approved intent)

| Do say | Don’t say |
|---|---|
| “Quick improve without a mic” | “Calibrated to studio reference” |
| “Saved for this speaker until you Retry” | “Works for any speaker in the world” |
| “For a better match, use Measure” | “Same as measuring” |
| “Safe limits on” | “Maximum bass boost” |

Home badge after apply: **`Narrow · Bluetooth box`** (path + category), not “Optimized ★★★★★”.

---

## 7. Conflict & upsell

| Situation | Behavior |
|---|---|
| Narrow applied; user later chooses Measure | Measure replaces Narrow after confirm |
| Measure exists; user Retry → Narrow | Confirm replace |
| User unhappy with Narrow | Primary CTA: **Try Measure**; secondary: different category |

---

## 8. Validation still required

Before trusting Narrow in product demos:

- [ ] Listening note: Narrow vs flat vs casual eqMac on user’s Sony / Alexa  
- [ ] Narrow vs Measure on same speaker — Narrow useful, not embarrassing  
- [ ] Exact Alexa/Echo model recorded for naming smoke test  

---

## 9. Checklist mapping (phase-1 §2.2)

- [x] Day-one inventory (name match, categories, BT-safe curves)  
- [x] Persist rules pointed at identity / Retry  
- [x] Honest marketing copy  
- [ ] Numeric curves + listening comparison (blocked on user listening trial)  

*Related:* `docs/paper-ux-flows.md`, `docs/safety-limits.md`, `docs/product-brief.md`.
