#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA="$REPO_ROOT/.derivedData-ui"
APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/NameSnap.app"
SCREENSHOT_DIR="$REPO_ROOT/fastlane/screenshots/en-US"
EVIDENCE_DIR="$REPO_ROOT/artifacts/app-store-refresh-2026-08-15"
BUNDLE_ID="com.marcuskim.namesnap"
IPHONE_UDID="B120D776-0741-4A93-96E2-30C8A0F00725"
IPAD_UDID="D50F78A3-83E0-4CD0-BA19-FC495946B5A6"
IDB_BIN="/Users/marcuskim/Library/Python/3.9/bin/idb"

SCREENSHOT_NAMES="Maya Chen|Jordan Brooks|Sofia Patel|Liam Carter|Zoe Martinez|Noah Williams|Ava Thompson|Ethan Nguyen|Priya Shah|Miles Robinson|Chloe Davis|Leo Garcia|Aria Morgan|Caleb Foster|Nina Park|Owen Lewis"

mkdir -p "$SCREENSHOT_DIR" "$EVIDENCE_DIR"

boot_and_prepare() {
  local udid="$1"
  xcrun simctl boot "$udid" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$udid" -b
  xcrun simctl install "$udid" "$APP_PATH"
  xcrun simctl status_bar "$udid" override \
    --time "9:41" \
    --batteryState charged \
    --batteryLevel 100 \
    --wifiBars 3 \
    --cellularBars 4
}

capture_state() {
  local udid="$1"
  local state="$2"
  local destination="$3"
  local scroll_count="${4:-0}"
  local scroll_distance="${5:-570}"

  xcrun simctl terminate "$udid" "$BUNDLE_ID" >/dev/null 2>&1 || true
  SIMCTL_CHILD_NAMESNAP_UI_SCREENSHOT_STATE="$state" \
    SIMCTL_CHILD_NAMESNAP_UI_SCREENSHOT_NAMES="$SCREENSHOT_NAMES" \
    xcrun simctl launch "$udid" "$BUNDLE_ID" >/dev/null
  if [[ "$udid" == "$IPHONE_UDID" ]]; then sleep 4; else sleep 8; fi

  if [[ "$scroll_count" -gt 0 ]]; then
    "$IDB_BIN" connect "$udid" --json >/dev/null 2>&1 || true
    local swipe_index=0
    while [[ "$swipe_index" -lt "$scroll_count" ]]; do
      "$IDB_BIN" ui swipe 220 790 220 "$((790 - scroll_distance))" --duration 0.45 --udid "$udid" >/dev/null
      sleep 0.5
      swipe_index=$((swipe_index + 1))
    done
  fi

  xcrun simctl io "$udid" screenshot "$destination" >/dev/null
}

echo "== build screenshot app =="
xcodebuild \
  -project "$REPO_ROOT/NameSnap.xcodeproj" \
  -scheme NameSnap \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$IPHONE_UDID" \
  -derivedDataPath "$DERIVED_DATA" \
  build

echo "== iPhone 6.9-inch screenshots =="
boot_and_prepare "$IPHONE_UDID"
capture_state "$IPHONE_UDID" input "$SCREENSHOT_DIR/01_iphone_69_add_16_names.png"
capture_state "$IPHONE_UDID" added "$SCREENSHOT_DIR/02_iphone_69_names_added.png"
capture_state "$IPHONE_UDID" classic "$SCREENSHOT_DIR/03_iphone_69_classic_ready.png" 1
capture_state "$IPHONE_UDID" wheel "$SCREENSHOT_DIR/04_iphone_69_wheel_ready.png"
capture_state "$IPHONE_UDID" winner-guitar "$SCREENSHOT_DIR/05_iphone_69_celebration.png"
capture_state "$IPHONE_UDID" history-preview "$SCREENSHOT_DIR/06_iphone_69_history.png"
capture_state "$IPHONE_UDID" reset-confirm "$SCREENSHOT_DIR/07_iphone_69_reset_confirm.png" 1 260

echo "== iPad 13-inch screenshots =="
boot_and_prepare "$IPAD_UDID"
capture_state "$IPAD_UDID" input "$SCREENSHOT_DIR/08_ipad_13_add_16_names.png"
capture_state "$IPAD_UDID" added "$SCREENSHOT_DIR/09_ipad_13_names_added.png"
capture_state "$IPAD_UDID" classic "$SCREENSHOT_DIR/10_ipad_13_classic_ready.png"
capture_state "$IPAD_UDID" wheel "$SCREENSHOT_DIR/11_ipad_13_wheel_ready.png"
capture_state "$IPAD_UDID" winner-guitar "$SCREENSHOT_DIR/12_ipad_13_celebration.png"
capture_state "$IPAD_UDID" history-preview "$SCREENSHOT_DIR/13_ipad_13_history.png"
capture_state "$IPAD_UDID" reset-confirm "$SCREENSHOT_DIR/14_ipad_13_reset_confirm.png" 1 260

echo "== evidence copy =="
cp "$SCREENSHOT_DIR/05_iphone_69_celebration.png" "$EVIDENCE_DIR/05_iphone_69_celebration.png"

echo "$SCREENSHOT_DIR"
