#!/usr/bin/env bash
set -euo pipefail

SCRIPT_SOURCE="${BASH_SOURCE[0]:-$0}"
REPO_ROOT="$(cd "$(dirname "$SCRIPT_SOURCE")/.." && pwd)"
SKILL_ROOT="/volumes/mracuth/skills/ios-simulator"
IOS_SIM_SCRIPT="$SKILL_ROOT/scripts/ios-sim.mjs"
SIM_HOST_UI_SCRIPT="$SKILL_ROOT/scripts/sim-host-ui.mjs"
STATE_FILE="$REPO_ROOT/.ios-sim-state.json"
ARTIFACTS_DIR="$REPO_ROOT/artifacts"
RUNS_DIR="$ARTIFACTS_DIR/runs"
LATEST_LINK="$ARTIFACTS_DIR/latest"
BUNDLE_ID="com.marcuskim.namesnap"
PROJECT_PATH="$REPO_ROOT/NameSnap.xcodeproj"
SCHEME="NameSnap"
SIM_NAME_DEFAULT="iPhone 17 Pro"
DERIVED_DATA_DIR="$REPO_ROOT/.derivedData"
APP_PATH_DEFAULT="$DERIVED_DATA_DIR/Build/Products/Debug-iphonesimulator/NameSnap.app"

if [[ -z "${DEVELOPMENT_TEAM:-}" ]]; then
  DEVELOPMENT_TEAM="$(rg -m 1 'DEVELOPMENT_TEAM = [A-Za-z0-9]+' "$PROJECT_PATH/project.pbxproj" | awk -F'= ' '{gsub(/;|[[:space:]]+/, "", $2); print $2}')"
fi

mkdir -p "$RUNS_DIR"
export IOS_SIM_STATE_FILE="$STATE_FILE"
