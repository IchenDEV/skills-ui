#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="${APP_NAME:-SkillsUI}"
EXECUTABLE_NAME="${EXECUTABLE_NAME:-SkillsUI}"
BUNDLE_ID="${BUNDLE_ID:-dev.ichendev.skillsui}"
APP_VERSION="${APP_VERSION:-0.1.0}"
APP_BUILD="${APP_BUILD:-1}"
VOLUME_NAME="${VOLUME_NAME:-SkillsUI}"
DIST_DIR="$ROOT_DIR/dist"
PACKAGING_DIR="$ROOT_DIR/Packaging"
APP_PATH="$DIST_DIR/$APP_NAME.app"
DMG_PATH="$DIST_DIR/$APP_NAME.dmg"
ICON_PATH="$PACKAGING_DIR/AppIcon.icns"
PLIST_TEMPLATE="$PACKAGING_DIR/Info.plist.template"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/skillsui-package.XXXXXX")"
DMG_STAGE_DIR="$TMP_DIR/dmg"
APP_CONTENTS_DIR="$APP_PATH/Contents"
APP_MACOS_DIR="$APP_CONTENTS_DIR/MacOS"
APP_RESOURCES_DIR="$APP_CONTENTS_DIR/Resources"
ACTIVE_DEVELOPER_DIR="$(xcode-select -p 2>/dev/null || true)"
XCODE_DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

if [[ -z "${DEVELOPER_DIR:-}" ]] && [[ "$ACTIVE_DEVELOPER_DIR" == "/Library/Developer/CommandLineTools" ]] && [[ -d "$XCODE_DEVELOPER_DIR" ]]; then
  export DEVELOPER_DIR="$XCODE_DEVELOPER_DIR"
fi

echo "Building $APP_NAME in release mode..."
swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"
EXECUTABLE_PATH="$BIN_DIR/$EXECUTABLE_NAME"

if [[ ! -x "$EXECUTABLE_PATH" ]]; then
  echo "Missing release executable at $EXECUTABLE_PATH" >&2
  exit 1
fi

if [[ ! -f "$ICON_PATH" ]]; then
  echo "Missing app icon at $ICON_PATH" >&2
  echo "Run ./scripts/render-app-icon.swift and iconutil before packaging." >&2
  exit 1
fi

if [[ ! -f "$PLIST_TEMPLATE" ]]; then
  echo "Missing Info.plist template at $PLIST_TEMPLATE" >&2
  exit 1
fi

rm -rf "$APP_PATH" "$DMG_PATH"
mkdir -p "$APP_MACOS_DIR" "$APP_RESOURCES_DIR" "$DMG_STAGE_DIR" "$DIST_DIR"

echo "Assembling app bundle..."
ditto "$EXECUTABLE_PATH" "$APP_MACOS_DIR/$EXECUTABLE_NAME"
chmod +x "$APP_MACOS_DIR/$EXECUTABLE_NAME"
ditto "$ICON_PATH" "$APP_RESOURCES_DIR/AppIcon.icns"

sed \
  -e "s|__APP_NAME__|$APP_NAME|g" \
  -e "s|__EXECUTABLE__|$EXECUTABLE_NAME|g" \
  -e "s|__BUNDLE_ID__|$BUNDLE_ID|g" \
  -e "s|__APP_VERSION__|$APP_VERSION|g" \
  -e "s|__APP_BUILD__|$APP_BUILD|g" \
  "$PLIST_TEMPLATE" > "$APP_CONTENTS_DIR/Info.plist"

plutil -lint "$APP_CONTENTS_DIR/Info.plist" >/dev/null
xattr -cr "$APP_PATH" || true

if [[ "${ADHOC_SIGN:-1}" == "1" ]]; then
  echo "Applying ad-hoc signature..."
  codesign --force --sign - "$APP_PATH"
  codesign --verify --deep --strict "$APP_PATH"
fi

echo "Preparing DMG contents..."
ditto "$APP_PATH" "$DMG_STAGE_DIR/$APP_NAME.app"
ln -s /Applications "$DMG_STAGE_DIR/Applications"

echo "Creating DMG..."
hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$DMG_STAGE_DIR" \
  -fs HFS+ \
  -format UDZO \
  -imagekey zlib-level=9 \
  "$DMG_PATH" >/dev/null

echo
echo "Created:"
echo "  App: $APP_PATH"
echo "  DMG: $DMG_PATH"
echo
echo "Note: this package is local-use only."
echo "It is ad-hoc signed by default and not notarized."
