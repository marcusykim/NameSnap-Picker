# NameSnap

Playful random name picker for classrooms, giveaways, party games, and streams.

## Core MVP
- Paste/import names (comma/newline)
- Spin animation with haptics
- No-repeat mode
- Include/exclude contestants
- Winner history (local only)

## Privacy
- No account
- No tracking
- Local-only data

## TestFlight Upload (Option B)

### One command setup (with App Store Connect API key or Apple ID)

Create these environment variables once in your shell:

```bash
export APP_STORE_CONNECT_API_KEY_PATH=/Users/marcuskim/.AuthKey_4HA95XB6S5.p8
export APP_STORE_CONNECT_API_KEY_ID=4HA95XB6S5
export APP_STORE_CONNECT_API_KEY_ISSUER_ID=67c52852-b22f-4e49-ad81-df53bf4476fb
export APP_STORE_CONNECT_API_KEY_ISSUER_ID=REPLACE_WITH_ISSUER_ID
```

Then run:

```bash
./scripts/namesnap-upload-testflight.sh

# Or Apple ID mode (if API auth is not available)
export APP_STORE_CONNECT_APPLE_ID=you@appleid.com
export APP_STORE_CONNECT_APP_SPECIFIC_PASSWORD='@env:APP_SPECIFIC_PASSWORD'
export APP_SPECIFIC_PASSWORD='xxxx xxxx xxxx xxxx xxxx'
export APP_STORE_CONNECT_PROVIDER_PUBLIC_ID=67c52852-b22f-4e49-ad81-df53bf4476fb  # if needed

./scripts/namesnap-upload-testflight.sh
```

Optional flags:

- `--build-number 4` to force a specific `CURRENT_PROJECT_VERSION`
- `--skip-validate` to skip `xcrun altool --validate-app`
- `--skip-upload` to only create the IPA
- `--key-path`, `--key-id`, `--issuer-id` to override env vars
