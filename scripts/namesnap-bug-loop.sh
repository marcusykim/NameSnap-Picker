#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/namesnap-env.sh"

SIM_NAME="${1:-$SIM_NAME_DEFAULT}"
STAMP="$(date +%Y%m%d-%H%M%S)"
RUN_DIR="$RUNS_DIR/$STAMP-bug-loop"
mkdir -p "$RUN_DIR"
ln -sfn "$RUN_DIR" "$LATEST_LINK"

{
  echo "== NameSnap bug loop =="
  echo "time: $(date)"
  echo "simulator: $SIM_NAME"
  echo "bundle: $BUNDLE_ID"
} | tee "$RUN_DIR/README.txt"

"$REPO_ROOT/scripts/namesnap-build-install-launch.sh" "$SIM_NAME" | tee "$RUN_DIR/bootstrap.txt"

node "$IOS_SIM_SCRIPT" ui summary --limit 30 --pretty > "$RUN_DIR/ui-summary-initial.json" || true
node "$IOS_SIM_SCRIPT" screenshot --out "$RUN_DIR/initial.png" --pretty > "$RUN_DIR/initial-screenshot.json" || true

echo "Manual/agent continuation from here:"
echo "- use ios-sim ui summary/find/tap/type when semantic path is available"
echo "- fall back to sim-host-ui tap/type/key when semantic path fails"
echo "- save artifacts into $RUN_DIR"
echo "$RUN_DIR"
