#!/usr/bin/env bash
# Personal Mac install only. Never call without green verify.
# Prefer Apple Development / Personal Team so Microphone + Screen Recording TCC grants stick.
# Do NOT re-sign with a fresh ad-hoc identity after each install — that resets TCC.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

eval "$("$ROOT/Scripts/resolve-signing.sh")"
if [[ "${SPEAKER_MASTER_FORCE_ADHOC:-}" == "1" ]]; then
  SIGN_IDENTITY="-"
  DEVELOPMENT_TEAM=""
  SIGN_MODE="adhoc"
fi

echo "==> Verify: swift test"
swift test --package-path .

echo "==> Build .app (signing mode=$SIGN_MODE team=${DEVELOPMENT_TEAM:-none})"
"$ROOT/Scripts/build-app.sh"

# Re-read after build (build-app resolves the same way).
eval "$("$ROOT/Scripts/resolve-signing.sh")"
if [[ "${SPEAKER_MASTER_FORCE_ADHOC:-}" == "1" ]]; then
  SIGN_IDENTITY="-"
  DEVELOPMENT_TEAM=""
  SIGN_MODE="adhoc"
fi

APP="$ROOT/build/Build/Products/Debug/SpeakerMaster.app"
if [[ ! -d "$APP" ]]; then
  echo "SpeakerMaster.app missing after build" >&2
  exit 1
fi

DEST="$HOME/Applications/SpeakerMaster.app"
mkdir -p "$HOME/Applications"
rm -rf "$DEST"
cp -R "$APP" "$DEST"

# Re-sign installed copy with the SAME identity used at build time (path change).
# Never switch to ad-hoc here when Apple Development was used — that breaks TCC.
echo "==> Sign installed copy with $SIGN_MODE ($SIGN_IDENTITY)"
codesign --force --deep --sign "$SIGN_IDENTITY" \
  --entitlements "$ROOT/App/SpeakerMaster/SpeakerMaster.entitlements" \
  "$DEST"

echo ""
echo "Installed: $DEST"
echo "Built at:  $APP"
codesign -dv --verbose=2 "$DEST" 2>&1 | grep -E 'Identifier=|Authority=|TeamIdentifier=|Signature=' || true
echo ""
if [[ "$SIGN_MODE" == "adhoc" ]]; then
  echo "WARNING: ad-hoc signing — macOS treats each rebuild as a new app."
  echo "  Microphone / Screen & System Audio Recording will prompt again."
  echo "  Install an Apple Development cert (free Personal Team) or set"
  echo "  SPEAKER_MASTER_DEVELOPMENT_TEAM=<TeamID> so TCC grants persist."
else
  echo "Signed with Apple Development team $DEVELOPMENT_TEAM — TCC should stick"
  echo "across rebuilds as long as bundle id + team stay the same."
  echo "Free Personal Team: first grant once; re-prompt only if team/bundle changes."
fi
echo ""
echo "Permissions (grant once, then leave them on):"
echo "  1. System Settings → Privacy & Security → Microphone → Speaker Master"
echo "  2. System Settings → Privacy & Security → Screen & System Audio Recording → Speaker Master"
echo "  3. If an old ad-hoc copy lingered: uncheck stale rows, toggle Speaker Master on, relaunch."
echo ""
echo "Open with: open \"$DEST\""
open "$DEST"
