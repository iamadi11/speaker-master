#!/usr/bin/env bash
# Local Mac crash gate. Build → run smokes → assert no new SpeakerMaster IPS.
# Exit 0 only when safe to install. Never install from this script.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

MODE="${1:-full}" # audition | measure | full | nonmic
HOLD_PAD_SEC="${SMOKE_HOLD_PAD_SEC:-2}"

pkill -x SpeakerMaster 2>/dev/null || true
sleep 0.5

echo "==> swift test"
swift test --package-path .

echo "==> build-app"
"$ROOT/Scripts/build-app.sh"

APP="$ROOT/build/Build/Products/Debug/SpeakerMaster.app"
BIN="$APP/Contents/MacOS/SpeakerMaster"
[[ -x "$BIN" ]] || { echo "missing binary $BIN" >&2; exit 1; }

IPS_DIR="$HOME/Library/Logs/DiagnosticReports"
before_list="$(mktemp)"
after_list="$(mktemp)"
ls -1 "$IPS_DIR"/SpeakerMaster-*.ips 2>/dev/null | sort >"$before_list" || true
BEFORE_COUNT=$(wc -l <"$before_list" | tr -d ' ')

ARGS=()
case "$MODE" in
  audition) ARGS=(--smoke-audition) ;;
  measure)  ARGS=(--smoke-measure) ;;
  full)     ARGS=(--smoke-full) ;;
  nonmic)   ARGS=(--qa-nonmic) ;;
  *) echo "usage: $0 [audition|measure|full|nonmic]" >&2; exit 2 ;;
esac

# Mic catalog gate (empty-picker regression). HAL list must be non-empty on this Mac.
if [[ "$MODE" == "measure" || "$MODE" == "full" ]]; then
  echo "==> dump-mics gate"
  set +e
  "$BIN" --dump-mics >/tmp/speaker-master-dump-mics.out 2>&1
  DUMP_EC=$?
  set -e
  cat /tmp/speaker-master-dump-mics.out || true
  if [[ "$DUMP_EC" -ne 0 ]]; then
    echo "dump-mics exited $DUMP_EC — Measure mic list empty or no selection" >&2
    exit 1
  fi
  if ! grep -q '^mic_count=[1-9]' /tmp/speaker-master-dump-mics.out; then
    echo "dump-mics reported empty mic_count" >&2
    exit 1
  fi
  if grep -qE 'Speaker Master Aggregate|CADefaultDeviceAggregate' /tmp/speaker-master-dump-mics.out; then
    echo "dump-mics still lists an aggregate as a Measure mic" >&2
    exit 1
  fi
  # Bluetooth speaker playback twins (UID …:input without Microphone in the name)
  # must not appear — they produce empty/weak Measure takes.
  if awk -F'uid=' '/^mic/ && $2 ~ /:input$/ {
      line=$0
      if (line !~ /[Mm]icrophone/ && line !~ /[Aa]ir[Pp]ods/ && line !~ /[Ii][Pp]hone/ && line !~ /[Ii][Pp]ad/) {
        print line; found=1
      }
    }
    END { exit found ? 0 : 1 }' /tmp/speaker-master-dump-mics.out
  then
    echo "dump-mics lists a speaker :input twin as a Measure mic" >&2
    exit 1
  fi
  # Continuity must not stick as default when Built-in exists (SM-33).
  if grep -q 'mic_fail=continuity_sticky' /tmp/speaker-master-dump-mics.out; then
    echo "dump-mics: Continuity mic stuck as default over Built-in" >&2
    exit 1
  fi
fi

# Narrow / Custom / Bypass / audition without Microphone TCC
if [[ "$MODE" == "full" || "$MODE" == "nonmic" ]]; then
  echo "==> qa-nonmic gate"
  set +e
  "$BIN" --qa-nonmic >/tmp/speaker-master-qa-nonmic.out 2>&1
  NONMIC_EC=$?
  set -e
  cat /tmp/speaker-master-qa-nonmic.out || true
  if [[ "$NONMIC_EC" -ne 0 ]]; then
    echo "qa-nonmic exited $NONMIC_EC" >&2
    exit 1
  fi
  if grep -q '=fail' /tmp/speaker-master-qa-nonmic.out; then
    echo "qa-nonmic reported failures" >&2
    exit 1
  fi
fi

echo "==> smoke mode=$MODE args=${ARGS[*]} (IPS before=$BEFORE_COUNT)"
set +e
"$BIN" "${ARGS[@]}" >/tmp/speaker-master-smoke.out 2>&1
EC=$?
set -e
# Surface mic/measure lines for the QA report
grep -E '^(smoke_|mic_)' /tmp/speaker-master-smoke.out || true

# Allow IPS flush
sleep "$HOLD_PAD_SEC"
ls -1 "$IPS_DIR"/SpeakerMaster-*.ips 2>/dev/null | sort >"$after_list" || true
AFTER_COUNT=$(wc -l <"$after_list" | tr -d ' ')
NEW_IPS="$(comm -13 "$before_list" "$after_list" || true)"
rm -f "$before_list" "$after_list"

echo "smoke_exit=$EC IPS $BEFORE_COUNT -> $AFTER_COUNT"

if [[ -n "$NEW_IPS" ]]; then
  echo "NEW_CRASH_REPORTS:" >&2
  echo "$NEW_IPS" >&2
  for f in $NEW_IPS; do
    echo "--- $f" >&2
    python3 - "$f" <<'PY' >&2
import json, pathlib, sys
text=pathlib.Path(sys.argv[1]).read_text(errors='replace')
dec=json.JSONDecoder(); i=0; parts=[]
while i < len(text):
    while i < len(text) and text[i].isspace(): i+=1
    if i>=len(text): break
    o,e=dec.raw_decode(text,i); parts.append(o); i=e
obj=parts[1] if len(parts)>1 else parts[0]
print('capture', obj.get('captureTime'), 'exc', obj.get('exception'))
print('thread', (obj.get('legacyInfo') or {}).get('threadTriggered'))
used=obj.get('usedImages') or []; ft=obj.get('faultingThread',0)
frames=(obj.get('threads') or [{}])[ft].get('frames') or []
for f in frames[:12]:
    img=used[f.get('imageIndex',-1)] if f.get('imageIndex') is not None else {}
    print(img.get('name'), f.get('symbol'))
PY
  done
  exit 1
fi

if [[ "$EC" -ne 0 ]]; then
  echo "smoke binary exited $EC (expected 0). log:" >&2
  tail -50 /tmp/speaker-master-smoke.out >&2 || true
  exit 1
fi

echo "SMOKE_PASS mode=$MODE"
echo "Built app OK for install: $APP"
