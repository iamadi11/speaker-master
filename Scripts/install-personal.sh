#!/usr/bin/env bash
# Personal Mac install only — free/ad-hoc signing. Never call without green verify.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> Verify: swift test"
swift test --package-path .

echo "==> Build .app"
"$ROOT/Scripts/build-app.sh"

APP="$ROOT/build/Build/Products/Debug/SpeakerMaster.app"
if [[ ! -d "$APP" ]]; then
  echo "SpeakerMaster.app missing after build" >&2
  exit 1
fi

echo "==> Ad-hoc sign (free / personal; sandbox off — required for process taps)"
codesign --force --deep --sign - \
  --entitlements "$ROOT/App/SpeakerMaster/SpeakerMaster.entitlements" \
  "$APP"

DEST="$HOME/Applications/SpeakerMaster.app"
mkdir -p "$HOME/Applications"
rm -rf "$DEST"
cp -R "$APP" "$DEST"
# Re-sign installed copy so TCC identity matches ~/Applications path.
codesign --force --deep --sign - \
  --entitlements "$ROOT/App/SpeakerMaster/SpeakerMaster.entitlements" \
  "$DEST"

echo ""
echo "Installed: $DEST"
echo "Built at:  $APP"
echo ""
echo "Permissions for system-wide EQ:"
echo "  1. Open the app and apply Auto (Narrow/Measure) or Custom."
echo "  2. When prompted, allow Screen & System Audio Recording"
echo "     (System Settings → Privacy & Security → Screen & System Audio Recording)."
echo "  3. If denied earlier: enable Speaker Master there, then Retry system EQ."
echo "  4. Measure also needs Microphone permission."
echo ""
echo "Open with: open \"$DEST\""
open "$DEST"
