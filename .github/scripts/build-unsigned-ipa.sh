#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
DERIVED_DATA_DIR="$BUILD_DIR/DerivedData"
ARCHIVE_PATH="$BUILD_DIR/TimeApp.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
PAYLOAD_DIR="$EXPORT_DIR/Payload"
APP_PATH="$ARCHIVE_PATH/Products/Applications/TimeApp.app"
EXTENSION_PATH="$APP_PATH/PlugIns/TimeShareExtension.appex"
IPA_PATH="$EXPORT_DIR/TimeApp-unsigned.ipa"
LOG_DIR="$BUILD_DIR/logs"

rm -rf "$DERIVED_DATA_DIR" "$ARCHIVE_PATH" "$EXPORT_DIR" "$LOG_DIR"
mkdir -p "$PAYLOAD_DIR" "$LOG_DIR"

cd "$ROOT_DIR"

xcodegen generate 2>&1 | tee "$LOG_DIR/xcodegen.log"
xcodebuild -version 2>&1 | tee "$LOG_DIR/xcodebuild-version.log"
xcodebuild -list -project TimeApp.xcodeproj 2>&1 | tee "$LOG_DIR/xcodebuild-list.log"

xcodebuild \
  -project TimeApp.xcodeproj \
  -scheme TimeApp \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "$ARCHIVE_PATH" \
  -derivedDataPath "$DERIVED_DATA_DIR" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  DEVELOPMENT_TEAM="" \
  archive 2>&1 | tee "$LOG_DIR/xcodebuild-archive.log"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Expected app bundle not found at $APP_PATH" >&2
  exit 1
fi

if [[ ! -d "$EXTENSION_PATH" ]]; then
  echo "Expected embedded extension not found at $EXTENSION_PATH" >&2
  exit 1
fi

/usr/bin/ditto "$APP_PATH" "$PAYLOAD_DIR/TimeApp.app"

(
  cd "$EXPORT_DIR"
  /usr/bin/ditto -c -k --sequesterRsrc --keepParent Payload "$(basename "$IPA_PATH")"
)

if [[ ! -f "$IPA_PATH" ]]; then
  echo "Expected IPA not found at $IPA_PATH" >&2
  exit 1
fi

shasum -a 256 "$IPA_PATH" | tee "$EXPORT_DIR/TimeApp-unsigned.ipa.sha256"
