#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="VPNStatusBar"
BUNDLE_ID="com.vpnstatusbar.VPNStatusBar"
MIN_SYSTEM_VERSION="13.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
WORK_DIR="$ROOT_DIR/work"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
SDKROOT="${SDKROOT:-$(xcrun --sdk macosx --show-sdk-path)}"

export SDKROOT
export CLANG_MODULE_CACHE_PATH="$WORK_DIR/clang-module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$WORK_DIR/clang-module-cache"
mkdir -p "$CLANG_MODULE_CACHE_PATH" "$WORK_DIR/swiftpm-cache" "$WORK_DIR/swiftpm-config" "$WORK_DIR/swiftpm-security"

SWIFT_OPTIONS=(
  --disable-sandbox
  --cache-path "$WORK_DIR/swiftpm-cache"
  --config-path "$WORK_DIR/swiftpm-config"
  --security-path "$WORK_DIR/swiftpm-security"
)

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

cd "$ROOT_DIR"
swift build "${SWIFT_OPTIONS[@]}"
BUILD_BINARY="$(swift build "${SWIFT_OPTIONS[@]}" --show-bin-path)/$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS"
cp "$BUILD_BINARY" "$APP_BINARY"
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
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

# A valid ad hoc signature is sufficient for running a locally built app.
# Distribution builds are signed and notarized by package_release.sh.
/usr/bin/codesign --force --sign - "$APP_BUNDLE"

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
