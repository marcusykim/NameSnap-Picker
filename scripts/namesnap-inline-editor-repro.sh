#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/namesnap-idb-env.sh"

STAMP="$(date +%Y%m%d-%H%M%S)"
RUN_DIR="$RUNS_DIR/$STAMP-inline-editor-repro"
mkdir -p "$RUN_DIR"
ln -sfn "$RUN_DIR" "$LATEST_LINK"

capture() {
  local name="$1"
  xcrun simctl io booted screenshot "$RUN_DIR/${name}.png" >/dev/null
}

snapshot_ui() {
  local name="$1"
  idb_ui ui describe-all --json > "$RUN_DIR/${name}.json"
}

fresh_launch() {
  xcrun simctl terminate booted "$BUNDLE_ID" >/dev/null 2>&1 || true
  xcrun simctl launch booted "$BUNDLE_ID" >/dev/null
  sleep 2
}

focus_textbox() {
  idb_ui ui tap "$IDB_TEXTFIELD_X" "$IDB_TEXTFIELD_Y" >/dev/null
  sleep 1
}

seed_names() {
  local names=("$@")
  local i=0
  for name in "${names[@]}"; do
    idb_ui ui text "$name" >/dev/null
    sleep 0.2
    if [[ $i -lt $((${#names[@]} - 1)) ]]; then
      idb_ui ui key "$IDB_KEY_RETURN" >/dev/null
      sleep 0.2
    fi
    i=$((i + 1))
  done
}

backspace_steps() {
  local count="$1"
  local i=1
  while [[ $i -le $count ]]; do
    idb_ui ui key "$IDB_KEY_BACKSPACE" >/dev/null
    sleep 0.2
    capture "backspace-${i}"
    snapshot_ui "backspace-${i}"
    i=$((i + 1))
  done
}

{
  echo "== NameSnap inline editor repro =="
  echo "time: $(date)"
  echo "udid: $IDB_UDID"
  echo "bundle: $BUNDLE_ID"
  echo "return_key: $IDB_KEY_RETURN"
  echo "backspace_key: $IDB_KEY_BACKSPACE"
} | tee "$RUN_DIR/README.txt"

fresh_launch
capture before-focus
snapshot_ui before-focus
focus_textbox
capture focused
snapshot_ui focused
seed_names Alice Bob Carol Dave Eve
capture names-seeded
snapshot_ui names-seeded
backspace_steps 12

echo "$RUN_DIR"
