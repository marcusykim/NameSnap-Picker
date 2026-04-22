#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/namesnap-env.sh"

LABEL="${1:-state}"
STAMP="$(date +%Y%m%d-%H%M%S)"
RUN_DIR="$RUNS_DIR/$STAMP-$LABEL"
mkdir -p "$RUN_DIR"
ln -sfn "$RUN_DIR" "$LATEST_LINK"

node "$IOS_SIM_SCRIPT" screenshot --out "$RUN_DIR/$LABEL.png" --pretty | tee "$RUN_DIR/screenshot.json" || true
node "$IOS_SIM_SCRIPT" ui summary --limit 20 --pretty | tee "$RUN_DIR/ui-summary.json" || true
node "$IOS_SIM_SCRIPT" logs show --last 2m --pretty | tee "$RUN_DIR/logs.json" || true

echo "$RUN_DIR"
