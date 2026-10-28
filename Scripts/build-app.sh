#!/usr/bin/env bash
# Generate Xcode project and build SpeakerMaster.app (Debug).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/App"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen required: brew install xcodegen" >&2
  exit 1
fi

restore_plist() {
  local src="$1"
  local dest="$2"
  cp "$src" "$dest"
}

# CI / unsigned hosts stay ad-hoc. Local personal installs prefer Apple Development.
# Force ad-hoc: SPEAKER_MASTER_FORCE_ADHOC=1
eval "$("$ROOT/Scripts/resolve-signing.sh")"
if [[ "${SPEAKER_MASTER_FORCE_ADHOC:-}" == "1" ]]; then
  SIGN_IDENTITY="-"
  DEVELOPMENT_TEAM=""
  SIGN_MODE="adhoc"
fi

echo "==> Signing: mode=$SIGN_MODE identity=$SIGN_IDENTITY team=${DEVELOPMENT_TEAM:-none}"

echo "==> xcodegen"
xcodegen generate

# XcodeGen rewrites Info.plist / entitlements to stubs; restore canonical copies.
echo "==> Restore Info.plist + entitlements (privacy + sandbox-off)"
restore_plist "$ROOT/App/SpeakerMaster/Info.plist.canonical" "$ROOT/App/SpeakerMaster/Info.plist" 2>/dev/null \
  || true
# Canonical sources live beside the targets; keep committed files as source of truth
# by re-writing from embedded heredocs if .canonical missing.
if ! plutil -extract NSAudioCaptureUsageDescription raw "$ROOT/App/SpeakerMaster/Info.plist" >/dev/null 2>&1; then
  cat > "$ROOT/App/SpeakerMaster/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleDisplayName</key>
	<string>Speaker Master</string>
	<key>CFBundleExecutable</key>
	<string>$(EXECUTABLE_NAME)</string>
	<key>CFBundleIdentifier</key>
	<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>$(PRODUCT_NAME)</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>$(MARKETING_VERSION)</string>
	<key>CFBundleVersion</key>
	<string>$(CURRENT_PROJECT_VERSION)</string>
	<key>LSApplicationCategoryType</key>
	<string>public.app-category.music</string>
	<key>LSMinimumSystemVersion</key>
	<string>$(MACOSX_DEPLOYMENT_TARGET)</string>
	<key>NSAppleEventsUsageDescription</key>
	<string>Speaker Master may open System Settings so you can grant Screen and System Audio Recording.</string>
	<key>NSAudioCaptureUsageDescription</key>
	<string>Speaker Master processes system audio so Auto and Custom EQ apply to Spotify, YouTube, and other apps — not only in-app audition.</string>
	<key>NSHumanReadableCopyright</key>
	<string>Copyright © 2026</string>
	<key>NSMicrophoneUsageDescription</key>
	<string>Speaker Master briefly records through the mic you select so Measure can improve this speaker. Captures stay on this Mac and are deleted after analysis.</string>
	<key>NSPrincipalClass</key>
	<string>NSApplication</string>
</dict>
</plist>
PLIST
fi

cat > "$ROOT/App/SpeakerMaster/SpeakerMaster.entitlements" <<'ENT'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.app-sandbox</key>
	<false/>
	<key>com.apple.security.device.audio-input</key>
	<true/>
</dict>
</plist>
ENT

SIGN_ARGS=(
  CODE_SIGNING_ALLOWED=YES
  CODE_SIGN_IDENTITY="$SIGN_IDENTITY"
)
if [[ -n "$DEVELOPMENT_TEAM" ]]; then
  SIGN_ARGS+=(
    DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM"
    CODE_SIGN_STYLE=Manual
  )
else
  SIGN_ARGS+=(
    DEVELOPMENT_TEAM=
    CODE_SIGN_STYLE=Manual
  )
fi

echo "==> xcodebuild"
xcodebuild \
  -project SpeakerMaster.xcodeproj \
  -scheme SpeakerMasterApp \
  -configuration Debug \
  -derivedDataPath "$ROOT/build" \
  -destination 'platform=macOS' \
  "${SIGN_ARGS[@]}" \
  build

APP="$ROOT/build/Build/Products/Debug/SpeakerMaster.app"
if [[ -d "$APP" ]]; then
  if ! plutil -extract NSAudioCaptureUsageDescription raw "$APP/Contents/Info.plist" >/dev/null 2>&1; then
    echo "NSAudioCaptureUsageDescription missing from built Info.plist" >&2
    exit 1
  fi
  # Ensure final signature matches resolved identity (Xcode sometimes leaves mixed state).
  codesign --force --deep --sign "$SIGN_IDENTITY" \
    --entitlements "$ROOT/App/SpeakerMaster/SpeakerMaster.entitlements" \
    "$APP"
  echo "Built: $APP"
  codesign -dv --verbose=2 "$APP" 2>&1 | grep -E 'Identifier=|Authority=|TeamIdentifier=|Signature=' || true
else
  echo "Build finished but .app not found at expected path" >&2
  exit 1
fi
