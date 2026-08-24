#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA="$REPO_ROOT/.derivedData-ui"
APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/NameSnap.app"
OUTPUT_DIR="$REPO_ROOT/AppStoreAssets/ReleasePreviews/en-US"
BUNDLE_ID="com.marcuskim.namesnap"
IDB_BIN="/Users/marcuskim/Library/Python/3.9/bin/idb"
IPHONE_UDID="B120D776-0741-4A93-96E2-30C8A0F00725"
IPAD_UDID="D50F78A3-83E0-4CD0-BA19-FC495946B5A6"
MUSIC_PATH="$REPO_ROOT/NameSnap/Sounds/techno_upbeat_alt_04.mp3"
SCREENSHOT_NAMES="Maya Chen|Jordan Brooks|Sofia Patel|Liam Carter|Zoe Martinez|Noah Williams|Ava Thompson|Ethan Nguyen|Priya Shah|Miles Robinson|Chloe Davis|Leo Garcia|Aria Morgan|Caleb Foster|Nina Park|Owen Lewis"
WORK_DIR="$(mktemp -d /tmp/namesnap-app-preview.XXXXXX)"

cleanup() {
  if [[ "$WORK_DIR" == /tmp/namesnap-app-preview.* && -d "$WORK_DIR" ]]; then
    rm -r "$WORK_DIR"
  fi
}
trap cleanup EXIT

mkdir -p "$OUTPUT_DIR"

if [[ ! -d "$APP_PATH" ]]; then
  xcodebuild \
    -project "$REPO_ROOT/NameSnap.xcodeproj" \
    -scheme NameSnap \
    -configuration Debug \
    -destination "platform=iOS Simulator,id=$IPHONE_UDID" \
    -derivedDataPath "$DERIVED_DATA" \
    build
fi

prepare_device() {
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

record_fixture() {
  local udid="$1"
  local state="$2"
  local destination="$3"
  local duration="$4"
  local action="${5:-none}"

  xcrun simctl terminate "$udid" "$BUNDLE_ID" >/dev/null 2>&1 || true
  xcrun simctl io "$udid" recordVideo --codec=h264 --force "$destination" >/dev/null 2>&1 &
  local recorder_pid=$!
  sleep 0.5
  SIMCTL_CHILD_NAMESNAP_UI_SCREENSHOT_STATE="$state" \
    SIMCTL_CHILD_NAMESNAP_UI_SCREENSHOT_NAMES="$SCREENSHOT_NAMES" \
    xcrun simctl launch "$udid" "$BUNDLE_ID" >/dev/null

  if [[ "$action" != "none" ]]; then
    "$IDB_BIN" connect "$udid" --json >/dev/null 2>&1 || true
    if [[ "$udid" == "$IPHONE_UDID" ]]; then
      if [[ "$action" == "wheel" ]]; then
        sleep 2.7
        "$IDB_BIN" ui swipe 220 790 220 410 --duration 0.7 --udid "$udid" >/dev/null
        sleep 0.6
        "$IDB_BIN" ui swipe 220 720 220 520 --duration 1.0 --udid "$udid" >/dev/null
      elif [[ "$action" == "history" ]]; then
        sleep 2.8
        "$IDB_BIN" ui swipe 220 810 220 340 --duration 0.9 --udid "$udid" >/dev/null
      fi
    else
      if [[ "$action" == "wheel" ]]; then
        sleep 3.0
        "$IDB_BIN" ui swipe 516 920 516 560 --duration 1.0 --udid "$udid" >/dev/null
      elif [[ "$action" == "history" ]]; then
        sleep 3.0
        "$IDB_BIN" ui swipe 516 1080 516 610 --duration 0.9 --udid "$udid" >/dev/null
      fi
    fi
  fi

  sleep "$duration"
  kill -INT "$recorder_pid" >/dev/null 2>&1 || true
  wait "$recorder_pid" || true
}

render_preview() {
  local prefix="$1"
  local width="$2"
  local height="$3"
  local output="$4"

  ffmpeg -y \
    -i "$WORK_DIR/${prefix}-winner.mov" \
    -i "$WORK_DIR/${prefix}-input.mov" \
    -i "$WORK_DIR/${prefix}-wheel.mov" \
    -i "$WORK_DIR/${prefix}-history.mov" \
    -i "$WORK_DIR/${prefix}-reset.mov" \
    -stream_loop -1 -i "$MUSIC_PATH" \
    -filter_complex \
      "[0:v]trim=start=2.05,setpts=PTS-STARTPTS,tpad=stop_mode=clone:stop_duration=5.60,trim=duration=5.60,fps=30,scale=${width}:${height}:flags=lanczos,setsar=1,format=yuv420p[v0]; \
       [1:v]trim=start=2.05,setpts=PTS-STARTPTS,tpad=stop_mode=clone:stop_duration=3.25,trim=duration=3.25,fps=30,scale=${width}:${height}:flags=lanczos,setsar=1,format=yuv420p[v1]; \
       [2:v]trim=start=2.05,setpts=PTS-STARTPTS,tpad=stop_mode=clone:stop_duration=4.65,trim=duration=4.65,fps=30,scale=${width}:${height}:flags=lanczos,setsar=1,format=yuv420p[v2]; \
       [3:v]trim=start=2.05,setpts=PTS-STARTPTS,tpad=stop_mode=clone:stop_duration=3.65,trim=duration=3.65,fps=30,scale=${width}:${height}:flags=lanczos,setsar=1,format=yuv420p[v3]; \
       [4:v]trim=start=2.05,setpts=PTS-STARTPTS,tpad=stop_mode=clone:stop_duration=3.25,trim=duration=3.25,fps=30,scale=${width}:${height}:flags=lanczos,setsar=1,format=yuv420p[v4]; \
       [v0][v1][v2][v3][v4]concat=n=5:v=1:a=0[outv]; \
       [5:a]atrim=duration=20.40,asetpts=PTS-STARTPTS,volume=0.28,afade=t=in:st=0:d=0.35,afade=t=out:st=19.35:d=1.05,aformat=sample_rates=48000:channel_layouts=stereo[outa]" \
    -map "[outv]" \
    -map "[outa]" \
    -c:v libx264 \
    -profile:v high \
    -level:v 4.0 \
    -b:v 11M \
    -minrate 11M \
    -maxrate 11M \
    -bufsize 22M \
    -x264-params "nal-hrd=cbr:force-cfr=1" \
    -pix_fmt yuv420p \
    -r 30 \
    -c:a aac \
    -b:a 256k \
    -ar 48000 \
    -ac 2 \
    -movflags +faststart \
    -shortest \
    "$output"
}

echo "== record iPhone 6.9-inch preview =="
prepare_device "$IPHONE_UDID"
record_fixture "$IPHONE_UDID" winner-guitar "$WORK_DIR/iphone-winner.mov" 7.4
record_fixture "$IPHONE_UDID" input "$WORK_DIR/iphone-input.mov" 5.1
record_fixture "$IPHONE_UDID" wheel "$WORK_DIR/iphone-wheel.mov" 3.3 wheel
record_fixture "$IPHONE_UDID" history-preview "$WORK_DIR/iphone-history.mov" 5.1
record_fixture "$IPHONE_UDID" reset-confirm "$WORK_DIR/iphone-reset.mov" 5.1

IPHONE_OUTPUT="$OUTPUT_DIR/NameSnap-AppPreview-IPHONE_67-886x1920.mp4"
render_preview iphone 886 1920 "$IPHONE_OUTPUT"
ffmpeg -y -ss 5 -i "$IPHONE_OUTPUT" -frames:v 1 -pix_fmt rgb24 "$OUTPUT_DIR/NameSnap-AppPreview-iPhone-Poster-5s.png" >/dev/null 2>&1

echo "== record iPad 13-inch preview =="
prepare_device "$IPAD_UDID"
record_fixture "$IPAD_UDID" winner-guitar "$WORK_DIR/ipad-winner.mov" 7.4
record_fixture "$IPAD_UDID" input "$WORK_DIR/ipad-input.mov" 5.1
record_fixture "$IPAD_UDID" wheel "$WORK_DIR/ipad-wheel.mov" 3.3 wheel
record_fixture "$IPAD_UDID" history-preview "$WORK_DIR/ipad-history.mov" 5.1
record_fixture "$IPAD_UDID" reset-confirm "$WORK_DIR/ipad-reset.mov" 5.1

IPAD_OUTPUT="$OUTPUT_DIR/NameSnap-AppPreview-IPAD_PRO_3GEN_129-1200x1600.mp4"
render_preview ipad 1200 1600 "$IPAD_OUTPUT"
ffmpeg -y -ss 5 -i "$IPAD_OUTPUT" -frames:v 1 -pix_fmt rgb24 "$OUTPUT_DIR/NameSnap-AppPreview-iPad-Poster-5s.png" >/dev/null 2>&1

printf '%s\n' "$IPHONE_OUTPUT" "$IPAD_OUTPUT"
