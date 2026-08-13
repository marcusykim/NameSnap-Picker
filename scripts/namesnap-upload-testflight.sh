#!/usr/bin/env bash
set -euo pipefail
set -o pipefail

source "$(dirname "$0")/namesnap-env.sh"

APP_STORE_CONNECT_API_KEY_PATH="${APP_STORE_CONNECT_API_KEY_PATH:-/Users/marcuskim/.AuthKey_4HA95XB6S5.p8}"
APP_STORE_CONNECT_API_KEY_ISSUER_ID="${APP_STORE_CONNECT_API_KEY_ISSUER_ID:-67c52852-b22f-4e49-ad81-df53bf4476fb}"
PRIVATE_KEY_DIR="${APP_STORE_CONNECT_API_KEY_DIR:-$HOME/.appstoreconnect/private_keys}"
DEFAULT_API_KEY_PATH="/Users/marcuskim/.AuthKey_4HA95XB6S5.p8"

APP_STORE_CONNECT_APPLE_ID="${APP_STORE_CONNECT_APPLE_ID:-${APPLE_ID:-}}"
APP_STORE_CONNECT_APP_SPECIFIC_PASSWORD="${APP_STORE_CONNECT_APP_SPECIFIC_PASSWORD:-${APPLE_APP_SPECIFIC_PASSWORD:-${APP_SPECIFIC_PASSWORD:-}}}"
APP_STORE_CONNECT_PROVIDER_PUBLIC_ID="${APP_STORE_CONNECT_PROVIDER_PUBLIC_ID:-${ASC_PROVIDER_PUBLIC_ID:-}}"

if [[ "${APP_STORE_CONNECT_APP_SPECIFIC_PASSWORD}" == @env:* ]]; then
  APP_STORE_CONNECT_APP_SPECIFIC_PASSWORD_NAME="${APP_STORE_CONNECT_APP_SPECIFIC_PASSWORD#@env:}"
  APP_STORE_CONNECT_APP_SPECIFIC_PASSWORD="${!APP_STORE_CONNECT_APP_SPECIFIC_PASSWORD_NAME:-}"
fi
if [[ "${APP_STORE_CONNECT_APP_SPECIFIC_PASSWORD}" == @keychain:* ]]; then
  APP_STORE_CONNECT_APP_SPECIFIC_PASSWORD_NAME="${APP_STORE_CONNECT_APP_SPECIFIC_PASSWORD#@keychain:}"
  APP_STORE_CONNECT_APP_SPECIFIC_PASSWORD="$(security find-generic-password -w -a "$APP_STORE_CONNECT_APPLE_ID" -s "$APP_STORE_CONNECT_APP_SPECIFIC_PASSWORD_NAME" 2>/dev/null || true)"
fi

discover_api_key_path() {
  local key_dir="$1"
  local file
  [[ -d "$key_dir" ]] || return 1
  while IFS= read -r file; do
    printf '%s\n' "$file"
    return 0
  done < <(rg --files "$key_dir" | rg '/(AuthKey_|ApiKey_).*\.p8$' )
  return 1
}

derive_api_key_id() {
  local key_path="$1"
  local file_name
  local key_name
  file_name="$(basename "$key_path")"
  # Accept both AuthKey_XXXXX.p8 and ApiKey_XXXXX.p8, and tolerate a leading dot.
  key_name="${file_name#./}"
  key_name="${key_name#.}"
  key_name="${key_name#ApiKey_}"
  key_name="${key_name#AuthKey_}"
  key_name="${key_name%.p8}"
  if [[ "$key_name" == "$file_name" ]] || [[ -z "$key_name" || "$key_name" == ".ApiKey"* || "$key_name" == ".AuthKey"* ]]; then
    return 1
  fi
  printf '%s\n' "$key_name"
}

is_placeholder() {
  local value="$1"
  local lower
  lower="$(printf '%s' "$value" | tr '[:upper:]' '[:lower:]')"
  [[ "$lower" == *xxxxxxxx* || "$lower" == *'replace'* || "$lower" == *'todo'* || "$value" == *'XXXXXXXXXX'* || "$value" == *'00000000-0000-0000-0000-000000000000'* ]]
}

resolve_api_key_path() {
  local path="$1"
  if [[ -z "$path" ]] || is_placeholder "$path" || [[ ! -f "$path" ]]; then
    return 1
  fi
  printf '%s\n' "$path"
}

if [[ -z "${APP_STORE_CONNECT_API_KEY_ID:-}" && -n "${APP_STORE_CONNECT_API_KEY_PATH:-}" ]]; then
  APP_STORE_CONNECT_API_KEY_ID="$(derive_api_key_id "$APP_STORE_CONNECT_API_KEY_PATH" || true)"
fi

SCRIPT_NAME="$(basename "$0")"
STAMP="$(date +%Y%m%d-%H%M%S)"
RUN_DIR="$RUNS_DIR/$STAMP-testflight"
ARCHIVE_PATH="$RUN_DIR/NameSnap.xcarchive"
IPA_PATH="$RUN_DIR/NameSnap.ipa"
EXPORT_OPTIONS_PATH="$RUN_DIR/ExportOptions.plist"

mkdir -p "$RUN_DIR"
ln -sfn "$RUN_DIR" "$LATEST_LINK"

usage() {
  cat <<EOF
Usage: $SCRIPT_NAME [--key-path <path>] [--key-id <id>] [--issuer-id <id>]
       [--apple-id <email>] [--app-password <password|@env:VAR|@keychain:NAME>]
       [--provider-public-id <id>] [--build-number <value>] [--skip-validate] [--skip-upload]

You can authenticate either with API key or Apple ID + app-specific password.

API key mode (preferred):
  - App Store Connect API Key (.p8) available as:
      1) --key-path / default APP_STORE_CONNECT_API_KEY_PATH / ASC_API_KEY_PATH
  - App Store Connect Key ID from App Store Connect as:
      1) --key-id / default APP_STORE_CONNECT_API_KEY_ID / ASC_API_KEY_ID
  - App Store Connect Issuer ID as:
      1) --issuer-id / default APP_STORE_CONNECT_API_KEY_ISSUER_ID / ASC_API_KEY_ISSUER_ID

Apple ID mode:
  - Apple ID email:
      1) --apple-id / default APP_STORE_CONNECT_APPLE_ID / APPLE_ID
  - App-specific password:
      1) --app-password / default APP_STORE_CONNECT_APP_SPECIFIC_PASSWORD
  - Provider public ID:
      1) --provider-public-id / default APP_STORE_CONNECT_PROVIDER_PUBLIC_ID / ASC_PROVIDER_PUBLIC_ID
  - App-specific password supports @env:VAR and @keychain:NAME.

Optional:
  - Exported build uses Release config; pass --build-number <value> to
    override CURRENT_PROJECT_VERSION for this run.
  - --skip-validate to skip xcrun altool --validate-app
  - --skip-upload to skip xcrun altool --upload-app
EOF
}

require_xcode_credentials() {
  if [[ -z "${APP_STORE_CONNECT_API_KEY_PATH:-}" ]]; then
    echo "Missing App Store Connect API key path. Set APP_STORE_CONNECT_API_KEY_PATH or pass --key-path." >&2
    exit 1
  fi

  if [[ ! -f "$APP_STORE_CONNECT_API_KEY_PATH" ]]; then
    echo "App Store Connect API key file not found: $APP_STORE_CONNECT_API_KEY_PATH" >&2
    exit 1
  fi

  if [[ -z "${APP_STORE_CONNECT_API_KEY_ID:-}" ]]; then
    echo "Missing App Store Connect API key ID. Set APP_STORE_CONNECT_API_KEY_ID or pass --key-id." >&2
    exit 1
  fi

  if [[ -z "${APP_STORE_CONNECT_API_KEY_ISSUER_ID:-}" ]]; then
    echo "Missing App Store Connect issuer ID. Set APP_STORE_CONNECT_API_KEY_ISSUER_ID or pass --issuer-id." >&2
    exit 1
  fi
}

require_apple_credentials() {
  if [[ -z "${APP_STORE_CONNECT_APPLE_ID:-}" ]]; then
    echo "Missing Apple ID. Set APP_STORE_CONNECT_APPLE_ID or pass --apple-id." >&2
    exit 1
  fi

  if [[ -z "${APP_STORE_CONNECT_APP_SPECIFIC_PASSWORD:-}" ]]; then
    echo "Missing Apple app-specific password. Set APP_STORE_CONNECT_APP_SPECIFIC_PASSWORD or pass --app-password." >&2
    exit 1
  fi
}

require_distribution_cert() {
  if ! security find-identity -v -p codesigning | rg -q "Apple Distribution|iPhone Distribution"; then
    echo "No signing certificate \"Apple Distribution\" or \"iPhone Distribution\" found in the login keychain." >&2
    echo "Xcode can generate/import distribution certificates under Accounts > Manage Certificates." >&2
    echo "Once one is available, rerun this script." >&2
    exit 1
  fi
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

BUILD_NUMBER=""
SKIP_VALIDATE=false
SKIP_UPLOAD=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --key-path)
      APP_STORE_CONNECT_API_KEY_PATH="$2"
      shift 2
      ;;
    --key-id)
      APP_STORE_CONNECT_API_KEY_ID="$2"
      shift 2
      ;;
    --issuer-id)
      APP_STORE_CONNECT_API_KEY_ISSUER_ID="$2"
      shift 2
      ;;
    --apple-id)
      APP_STORE_CONNECT_APPLE_ID="$2"
      shift 2
      ;;
    --app-password)
      APP_STORE_CONNECT_APP_SPECIFIC_PASSWORD="$2"
      shift 2
      ;;
    --provider-public-id)
      APP_STORE_CONNECT_PROVIDER_PUBLIC_ID="$2"
      shift 2
      ;;
    --build-number)
      BUILD_NUMBER="$2"
      shift 2
      ;;
    --skip-validate)
      SKIP_VALIDATE=true
      shift
      ;;
    --skip-upload)
      SKIP_UPLOAD=true
      shift
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

# Prefer environment variable aliases if caller passed none.
APP_STORE_CONNECT_API_KEY_PATH="$(resolve_api_key_path "$APP_STORE_CONNECT_API_KEY_PATH" || true)"
if [[ -z "${APP_STORE_CONNECT_API_KEY_PATH:-}" ]]; then
  APP_STORE_CONNECT_API_KEY_PATH="$(resolve_api_key_path "${ASC_API_KEY_PATH:-}" || true)"
fi
if [[ -z "${APP_STORE_CONNECT_API_KEY_PATH:-}" ]]; then
  APP_STORE_CONNECT_API_KEY_PATH="$(discover_api_key_path "$PRIVATE_KEY_DIR" || true)"
fi
if [[ -z "${APP_STORE_CONNECT_API_KEY_PATH:-}" ]]; then
  APP_STORE_CONNECT_API_KEY_PATH="$DEFAULT_API_KEY_PATH"
fi

if [[ -n "${APP_STORE_CONNECT_API_KEY_ID:-}" ]] && is_placeholder "${APP_STORE_CONNECT_API_KEY_ID:-}"; then
  APP_STORE_CONNECT_API_KEY_ID=""
fi
if [[ -z "${APP_STORE_CONNECT_API_KEY_ID:-}" ]] && [[ -n "${ASC_API_KEY_ID:-}" ]] && ! is_placeholder "$ASC_API_KEY_ID"; then
  APP_STORE_CONNECT_API_KEY_ID="$ASC_API_KEY_ID"
fi
if [[ -z "${APP_STORE_CONNECT_API_KEY_ID:-}" ]]; then
  APP_STORE_CONNECT_API_KEY_ID="$(derive_api_key_id "$APP_STORE_CONNECT_API_KEY_PATH" || true)"
fi

if [[ -n "${APP_STORE_CONNECT_API_KEY_ISSUER_ID:-}" ]] && is_placeholder "${APP_STORE_CONNECT_API_KEY_ISSUER_ID:-}"; then
  APP_STORE_CONNECT_API_KEY_ISSUER_ID=""
fi
if [[ -z "${APP_STORE_CONNECT_API_KEY_ISSUER_ID:-}" ]] && [[ -n "${ASC_API_KEY_ISSUER_ID:-}" ]] && ! is_placeholder "$ASC_API_KEY_ISSUER_ID"; then
  APP_STORE_CONNECT_API_KEY_ISSUER_ID="$ASC_API_KEY_ISSUER_ID"
fi

if [[ -n "${APP_STORE_CONNECT_PROVIDER_PUBLIC_ID:-}" ]] && is_placeholder "${APP_STORE_CONNECT_PROVIDER_PUBLIC_ID:-}"; then
  APP_STORE_CONNECT_PROVIDER_PUBLIC_ID=""
fi

HAS_API_KEY_CREDENTIALS=false
if [[ -n "${APP_STORE_CONNECT_API_KEY_PATH:-}" ]] && [[ -f "$APP_STORE_CONNECT_API_KEY_PATH" ]] && [[ -n "${APP_STORE_CONNECT_API_KEY_ID:-}" ]] && [[ -n "${APP_STORE_CONNECT_API_KEY_ISSUER_ID:-}" ]]; then
  HAS_API_KEY_CREDENTIALS=true
fi

HAS_APPLE_CREDENTIALS=false
if [[ -n "${APP_STORE_CONNECT_APPLE_ID:-}" ]] && [[ -n "${APP_STORE_CONNECT_APP_SPECIFIC_PASSWORD:-}" ]]; then
  HAS_APPLE_CREDENTIALS=true
fi

AUTH_MODE="none"
AUTH_ARGS=()
XCODEBUILD_AUTH_ARGS=()
ALTOOL_ARGS=()

if [[ "$HAS_API_KEY_CREDENTIALS" == true ]]; then
  AUTH_MODE="api"
elif [[ "$HAS_APPLE_CREDENTIALS" == true ]]; then
  AUTH_MODE="apple"
fi

if [[ "$AUTH_MODE" == "api" ]]; then
  require_xcode_credentials
  AUTH_ARGS=(
    -authenticationKeyPath "$APP_STORE_CONNECT_API_KEY_PATH"
    -authenticationKeyID "$APP_STORE_CONNECT_API_KEY_ID"
    -authenticationKeyIssuerID "$APP_STORE_CONNECT_API_KEY_ISSUER_ID"
  )
  XCODEBUILD_AUTH_ARGS=("${AUTH_ARGS[@]}")
  ALTOOL_ARGS=(
    --api-key "$APP_STORE_CONNECT_API_KEY_ID"
    --api-issuer "$APP_STORE_CONNECT_API_KEY_ISSUER_ID"
    --p8-file-path "$APP_STORE_CONNECT_API_KEY_PATH"
  )
elif [[ "$AUTH_MODE" == "apple" ]]; then
  require_apple_credentials
  ALTOOL_ARGS=(
    -u "$APP_STORE_CONNECT_APPLE_ID"
    -p "$APP_STORE_CONNECT_APP_SPECIFIC_PASSWORD"
  )
  if [[ -n "${APP_STORE_CONNECT_PROVIDER_PUBLIC_ID:-}" ]]; then
    ALTOOL_ARGS+=(--provider-public-id "$APP_STORE_CONNECT_PROVIDER_PUBLIC_ID")
  fi
else
  echo "Missing upload credentials." >&2
  echo "Set API key vars (APP_STORE_CONNECT_API_KEY_*) or Apple ID vars (APP_STORE_CONNECT_APPLE_ID + APP_STORE_CONNECT_APP_SPECIFIC_PASSWORD)." >&2
  exit 1
fi

echo "Using $AUTH_MODE App Store Connect authentication."

cat >"$EXPORT_OPTIONS_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store-connect</string>
  <key>destination</key>
  <string>export</string>
  <key>teamID</key>
  <string>${DEVELOPMENT_TEAM}</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>uploadSymbols</key>
  <true/>
  <key>generateAppStoreInformation</key>
  <true/>
</dict>
</plist>
EOF

XCODEBUILD_ARGS=(
  -scheme "$SCHEME"
  -project "$PROJECT_PATH"
  -configuration Release
  -archivePath "$ARCHIVE_PATH"
  -destination "generic/platform=iOS"
  -allowProvisioningUpdates
)
if [[ "${#XCODEBUILD_AUTH_ARGS[@]}" -gt 0 ]]; then
  XCODEBUILD_ARGS+=("${XCODEBUILD_AUTH_ARGS[@]}")
fi

if [[ -n "$BUILD_NUMBER" ]]; then
  XCODEBUILD_ARGS+=(CURRENT_PROJECT_VERSION="$BUILD_NUMBER")
fi

echo "== archive =="
xcodebuild archive "${XCODEBUILD_ARGS[@]}" | tee "$RUN_DIR/archive.log"

if [[ ! -d "$ARCHIVE_PATH" ]]; then
  echo "Archive missing: $ARCHIVE_PATH" >&2
  exit 1
fi

echo "== export =="
require_distribution_cert
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$RUN_DIR" \
  -exportOptionsPlist "$EXPORT_OPTIONS_PATH" \
  | tee "$RUN_DIR/export.log"

if [[ ! -f "$IPA_PATH" ]]; then
  IPA_PATH="$(find "$RUN_DIR" -maxdepth 1 -name '*.ipa' | head -n 1 || true)"
  if [[ -z "$IPA_PATH" ]]; then
    echo "IPA not found in $RUN_DIR" >&2
    exit 1
  fi
fi

echo "== exported ipa =="
echo "$IPA_PATH"

if [[ "$SKIP_VALIDATE" == false ]]; then
  echo "== validate app =="
  xcrun altool --validate-app -f "$IPA_PATH" "${ALTOOL_ARGS[@]}" --show-progress --output-format normal | tee "$RUN_DIR/validate.log"
fi

if [[ "$SKIP_UPLOAD" == false ]]; then
  echo "== upload to App Store Connect =="
  xcrun altool --upload-app -f "$IPA_PATH" "${ALTOOL_ARGS[@]}" --wait --show-progress --output-format normal | tee "$RUN_DIR/upload.log"
fi

echo "$RUN_DIR"
