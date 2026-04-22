#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/namesnap-env.sh"

echo "== NameSnap automation health =="
echo "repo: $REPO_ROOT"
echo "ios-sim script: $IOS_SIM_SCRIPT"
echo "host-ui script: $SIM_HOST_UI_SCRIPT"
echo "bundle id: $BUNDLE_ID"
echo "state file: $STATE_FILE"

echo "\n-- binaries --"
command -v node
command -v xcrun
command -v xcodebuild
command -v ffmpeg || true
command -v idb || true
command -v idb_companion || true

echo "\n-- ios-sim health --"
node "$IOS_SIM_SCRIPT" health --pretty || true

echo "\n-- simulators --"
node "$IOS_SIM_SCRIPT" list --pretty || true

echo "\n-- simulator window bounds (fallback path) --"
node "$SIM_HOST_UI_SCRIPT" bounds || true
