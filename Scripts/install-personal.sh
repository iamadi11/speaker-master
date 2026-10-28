#!/usr/bin/env bash
# Personal Mac install only — free/ad-hoc signing. Never call without green verify.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> Verify: swift test"
swift test --package-path .

APP_CANDIDATES=(
  "$ROOT/build/Build/Products/Debug/SpeakerMaster.app"
  "$ROOT/DerivedData/Build/Products/Debug/SpeakerMaster.app"
  "$ROOT/App/build/Build/Products/Debug/SpeakerMaster.app"
  "$ROOT/App/SpeakerMaster/build/Debug/SpeakerMaster.app"
)

APP=""
for candidate in "${APP_CANDIDATES[@]}"; do
  if [[ -d "$candidate" ]]; then
    APP="$candidate"
    break
  fi
done

if [[ -z "$APP" ]]; then
  echo "==> No .app yet — building"
  "$ROOT/Scripts/build-app.sh"
  APP="$ROOT/build/Build/Products/Debug/SpeakerMaster.app"
fi

if [[ ! -d "$APP" ]]; then
  echo "SpeakerMaster.app missing after build" >&2
  exit 1
fi

echo "==> Ad-hoc sign (free / personal)"
codesign --force --deep --sign - "$APP"

DEST="$HOME/Applications/SpeakerMaster.app"
mkdir -p "$HOME/Applications"
rm -rf "$DEST"
cp -R "$APP" "$DEST"
echo "Installed: $DEST"
echo "Open with: open \"$DEST\""
open "$DEST"
