#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/namesnap-env.sh"

SIM_NAME="${1:-$SIM_NAME_DEFAULT}"
STAMP="$(date +%Y%m%d-%H%M%S)"
RUN_DIR="$RUNS_DIR/$STAMP"
mkdir -p "$RUN_DIR"
ln -sfn "$RUN_DIR" "$LATEST_LINK"

echo "== select + boot simulator =="
node "$IOS_SIM_SCRIPT" select --name "$SIM_NAME" --runtime "iOS" --boot --pretty | tee "$RUN_DIR/select.json"

echo "== build =="
xcodebuild \
  -scheme "$SCHEME" \
  -project "$PROJECT_PATH" \
  -configuration Debug \
  -destination "platform=iOS Simulator,name=$SIM_NAME" \
  -derivedDataPath "$DERIVED_DATA_DIR" \
  build | tee "$RUN_DIR/build.log"

echo "== install =="
node "$IOS_SIM_SCRIPT" app install --app "$APP_PATH_DEFAULT" --pretty | tee "$RUN_DIR/install.json"

echo "== launch =="
node "$IOS_SIM_SCRIPT" app launch --bundle-id "$BUNDLE_ID" --pretty | tee "$RUN_DIR/launch.json"

echo "== screenshot =="
node "$IOS_SIM_SCRIPT" screenshot --out "$RUN_DIR/launch-screen.png" --pretty | tee "$RUN_DIR/screenshot.json"

echo "$RUN_DIR"
