#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/namesnap-env.sh"
export PATH="$HOME/Library/Python/3.9/bin:$PATH"
IDB_UDID_DEFAULT="2228655B-0F36-42AC-BE94-B2F86C23390F"
IDB_UDID="${IDB_UDID:-$IDB_UDID_DEFAULT}"
IDB_TEXTFIELD_X="204"
IDB_TEXTFIELD_Y="209"
IDB_KEY_RETURN="40"
IDB_KEY_BACKSPACE="42"

require_idb() {
  command -v idb >/dev/null 2>&1 || {
    echo "idb CLI not found on PATH. Expected at $HOME/Library/Python/3.9/bin/idb" >&2
    exit 1
  }
}

ensure_idb_connected() {
  require_idb
  idb connect "$IDB_UDID" --json >/dev/null 2>&1 || true
}

idb_ui() {
  ensure_idb_connected
  idb "$@" --udid "$IDB_UDID"
}
