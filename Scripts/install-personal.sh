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
  echo "No .app bundle yet (scaffold stage). Domain package verified."
  echo "When the Xcode app target exists, build it then re-run this script."
  exit 0
fi

echo "==> Ad-hoc sign (free / personal)"
codesign --force --deep --sign - "$APP"

DEST="$HOME/Applications/SpeakerMaster.app"
mkdir -p "$HOME/Applications"
rm -rf "$DEST"
cp -R "$APP" "$DEST"
echo "Installed: $DEST"
echo "Open with: open \"$DEST\""
