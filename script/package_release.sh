#!/usr/bin/env bash
set -euo pipefail

APP_NAME="VPNStatusBar"
BUNDLE_ID="com.vpnstatusbar.VPNStatusBar"
MIN_SYSTEM_VERSION="13.0"
VERSION="${VERSION:-1.0.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
NOTARY_PROFILE="${NOTARY_PROFILE:-VPNStatusBar}"
UNSIGNED=false

usage() {
  cat <<'USAGE'
usage: ./script/package_release.sh [--unsigned]

Creates a universal arm64/x86_64 release in outputs/VPNStatusBar.zip.

The normal workflow requires:
  DEVELOPER_ID_APPLICATION  Full Developer ID Application identity
  NOTARY_PROFILE            notarytool Keychain profile (default: VPNStatusBar)

Use --unsigned only to validate the universal package locally. That archive is
not suitable for sharing because Gatekeeper will not trust it.
USAGE
}

case "${1:-}" in
  "") ;;
  --unsigned) UNSIGNED=true ;;
  --help|-h) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac

if [[ "$UNSIGNED" == false && -z "${DEVELOPER_ID_APPLICATION:-}" ]]; then
  echo "error: DEVELOPER_ID_APPLICATION is required for a distributable release." >&2
  echo "Run with --unsigned only for local packaging validation." >&2
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
OUTPUT_DIR="$ROOT_DIR/outputs"
WORK_DIR="$ROOT_DIR/work"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
APP_ICON="$ROOT_DIR/Resources/AppIcon.icns"
ARCHIVE="$OUTPUT_DIR/$APP_NAME.zip"
ARM64_SCRATCH="$WORK_DIR/release-arm64"
X86_64_SCRATCH="$WORK_DIR/release-x86_64"

SDKROOT="${SDKROOT:-$(xcrun --sdk macosx --show-sdk-path)}"
export SDKROOT
export CLANG_MODULE_CACHE_PATH="$WORK_DIR/clang-module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$WORK_DIR/clang-module-cache"
mkdir -p \
  "$CLANG_MODULE_CACHE_PATH" \
  "$WORK_DIR/swiftpm-cache" \
  "$WORK_DIR/swiftpm-config" \
  "$WORK_DIR/swiftpm-security" \
  "$OUTPUT_DIR"

SWIFT_OPTIONS=(
  --disable-sandbox
  --cache-path "$WORK_DIR/swiftpm-cache"
  --config-path "$WORK_DIR/swiftpm-config"
  --security-path "$WORK_DIR/swiftpm-security"
)

build_architecture() {
  local triple="$1"
  local scratch_path="$2"
  swift build \
    --configuration release \
    --triple "$triple" \
    --scratch-path "$scratch_path" \
    "${SWIFT_OPTIONS[@]}"
}

cd "$ROOT_DIR"
build_architecture "arm64-apple-macosx$MIN_SYSTEM_VERSION" "$ARM64_SCRATCH"
build_architecture "x86_64-apple-macosx$MIN_SYSTEM_VERSION" "$X86_64_SCRATCH"

ARM64_BINARY="$ARM64_SCRATCH/arm64-apple-macosx/release/$APP_NAME"
X86_64_BINARY="$X86_64_SCRATCH/x86_64-apple-macosx/release/$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
/usr/bin/lipo -create "$ARM64_BINARY" "$X86_64_BINARY" -output "$APP_BINARY"
cp "$APP_ICON" "$APP_RESOURCES/AppIcon.icns"
chmod +x "$APP_BINARY"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon.icns</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$BUILD_NUMBER</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

/usr/bin/plutil -lint "$INFO_PLIST"

if [[ "$UNSIGNED" == true ]]; then
  /usr/bin/codesign --force --sign - "$APP_BUNDLE"
else
  /usr/bin/codesign \
    --force \
    --options runtime \
    --timestamp \
    --sign "$DEVELOPER_ID_APPLICATION" \
    "$APP_BUNDLE"
fi

/usr/bin/codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
/usr/bin/lipo -archs "$APP_BINARY"

rm -f "$ARCHIVE"
/usr/bin/ditto --norsrc --noextattr --noqtn --noacl \
  -c -k --keepParent "$APP_BUNDLE" "$ARCHIVE"

if [[ "$UNSIGNED" == false ]]; then
  xcrun notarytool submit "$ARCHIVE" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait
  xcrun stapler staple "$APP_BUNDLE"
  xcrun stapler validate "$APP_BUNDLE"

  rm -f "$ARCHIVE"
  /usr/bin/ditto --norsrc --noextattr --noqtn --noacl \
    -c -k --keepParent "$APP_BUNDLE" "$ARCHIVE"
  /usr/sbin/spctl --assess --type execute --verbose=2 "$APP_BUNDLE"
fi

echo "Created $ARCHIVE"
