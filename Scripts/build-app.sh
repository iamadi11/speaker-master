#!/usr/bin/env bash
# Generate Xcode project and build SpeakerMaster.app (Debug).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/App"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen required: brew install xcodegen" >&2
  exit 1
fi

echo "==> xcodegen"
xcodegen generate

echo "==> xcodebuild"
xcodebuild \
  -project SpeakerMaster.xcodeproj \
  -scheme SpeakerMasterApp \
  -configuration Debug \
  -derivedDataPath "$ROOT/build" \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_ALLOWED=YES \
  build

APP="$ROOT/build/Build/Products/Debug/SpeakerMaster.app"
if [[ -d "$APP" ]]; then
  echo "Built: $APP"
else
  echo "Build finished but .app not found at expected path" >&2
  exit 1
fi
