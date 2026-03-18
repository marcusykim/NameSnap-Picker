# NameSnap App Store Prep

_Generated: 2026-03-10_

This doc is a single place to track App Store submission tasks and provides paste-ready copy for App Store Connect.

## 1) Submission Checklist (App Store Connect + Review)

- App information
- App Name: `NameSnap Picker`
- Subtitle: `Fair Random Name Picker`
- Primary Language: `English (U.S.)`
- Category: pick primary/secondary (suggested: `Utilities` primary; `Entertainment` secondary)
- Age Rating: `4+`
- Publisher Display Name: `Marcus Kim`
- Bundle ID: `com.marcuskim.namesnap`
- SKU: `namesnap-ios-001`

- Pricing and availability
- Current plan in repo: Paid app, `Tier 1 ($0.99 US)`.
- Double-check against monetization in build.
- The app includes StoreKit purchase logic for `namesnap.unlimited_contestants_099` (“Unlimited contestants” unlock).
- Decide monetization:
- Option A: Paid app, no IAP (remove IAP feature + product from App Store Connect).
- Option B: Free app with IAP unlock (common pattern; update app price to Free).
- Option C: Paid app + IAP (allowed; ensure it’s intentional and clearly explained in metadata).

- In-App Purchase setup (only if keeping IAP)
- IAP type: Non-Consumable (recommended for permanent unlock)
- Product ID: `namesnap.unlimited_contestants_099`
- Reference name: `Unlimited Contestants`
- Display name: `Unlimited Contestants`
- IAP description: `Remove the contestant limit and run bigger raffles, classes, and games.`
- IAP review notes: `In Settings, tap Upgrade to purchase. Restore is available via Restore Purchases.`
- Attach IAP to the submitted version if your ASC flow requires it.
- Reviewer account: not needed (no login).

- App privacy (Nutrition Label)
- Data collected: `None` (ensure this matches the actual build; no analytics/ads SDKs).
- Tracking: `No`
- Data linked to you: `None`
- Data used to track you: `None`
- Notes: app stores participant names and winner history locally on device.

- Export compliance
- If you do not use custom encryption beyond Apple’s OS-provided HTTPS/TLS, typically you can answer “No” to using non-exempt encryption.
- Confirm based on your exact build and any added dependencies.

- Content rights + safety
- Third-party content: none expected.
- User-generated content: users paste names; no sharing or network upload.

- Store listing assets
- App icon: 1024x1024 (existing asset: `NameSnap-Icon-1024-final.png` in `AppStoreAssets/`)
- Screenshots: at least one 6.9" class iPhone + one smaller size (shot list below)
- Optional: iPad screenshots (folder exists in `AppStoreAssets/Final_Assets_2026-02-23/Screenshots_iPad_13in_2048x2732`)
- App preview videos (optional; multiple `NameSnap ... Preview ... .mp4` files exist at repo root)

- Review notes (for the binary submission)
- Provide a short explanation: app is a random name picker; local-only; no account.
- If IAP exists, mention where the paywall/upgrade UI appears and how to restore.

## 2) Paste-Ready App Store Connect Copy

### App Name
`NameSnap Picker`

### Subtitle
`Fair Random Name Picker`

### Promotional Text
Stop overthinking and pick instantly. NameSnap makes random picks feel fun, fair, and fast for classrooms, giveaways, games, and live streams.

### Keywords (aim for 100 chars total)
`random,name,picker,raffle,giveaway,classroom,wheel,contest,lottery,draw,selector,spinner,winner`

### Description
NameSnap is a playful random name picker built for speed.

Paste names, tap Spin, and get a fair winner in seconds.

Perfect for:
- Classroom participation
- Giveaways and raffles
- Team picks and party games
- Livestream audience contests

What you can do:
- Paste names from any list (comma or line-separated)
- Spin with haptics for fun reveal moments
- Turn on no-repeat mode to avoid duplicate winners
- Include/exclude participants with one tap
- Track recent winners

Built to be simple:
No accounts. No tracking. No clutter.
Just open, paste, and pick.

NameSnap is designed for moments where you need a quick, fair decision and want it to feel exciting.

### First Release “What’s New”
- Launching NameSnap
- Paste names and spin a random winner instantly
- No-repeat mode with quick reset
- Include/exclude contestants on the fly
- Winner history for recent draws

## 3) Screenshot Shot List + Captions (iPhone)

Recommended devices: iPhone 17 Pro Max (or latest 6.9" class) + one smaller phone size.

1. Hero: Main screen with loaded names + Spin button visible. Caption: `Pick a winner in seconds`
2. Input: Text input area with pasted contestant list. Caption: `Paste names from any list`
3. Result: Winner highlighted after spin. Caption: `Fun reveal with every spin`
4. No Repeat: Toggle on + reset pool button visible. Caption: `No repeats until you reset`
5. Include/Exclude: Contestant checklist with some disabled. Caption: `Include or skip any contestant`
6. History: Recent winners section populated. Caption: `See recent winners instantly`

Caption alternatives:
- `Fair picks for class, games, and giveaways`
- `Clean, fast, and distraction-free`
- `No account. No tracking. Local-only`

## 4) URLs + Contact (from repo values)

- Support URL: `https://halved-fan-e5f.notion.site/NameSnap-Support-Privacy-311af69cbc3a80d5b757de3d27b04c6c`
- Marketing URL: `https://halved-fan-e5f.notion.site/NameSnap-Support-Privacy-311af69cbc3a80d5b757de3d27b04c6c`
- Privacy Policy URL: `https://halved-fan-e5f.notion.site/NameSnap-Support-Privacy-311af69cbc3a80d5b757de3d27b04c6c`
- Support Email: `Mracuth@gmail.com`
- Contact name: `Marcus Kim`

## 5) Support + Privacy Policy (paste-ready text)

_Last updated: 2026-02-23_

### Support
If you need help, found a bug, or want to suggest a feature, contact:

Marcus Kim
Email: Mracuth@gmail.com

### Privacy Policy
NameSnap is designed to be privacy-first.

- No account required
- No analytics tracking
- No third-party ads
- No data sold or shared
- All app data stays local on your device

Data we collect: none.

Data stored on device (for functionality):
- Entered participant names
- Winner history
- App preferences (such as no-repeat mode)

This data is never transmitted to external servers by the app.

Children’s privacy:
NameSnap does not knowingly collect personal information from anyone, including children.

Changes to this policy:
If this policy changes in future releases, the updated version will be posted with a new “Last updated” date.

Privacy contact:
Marcus Kim
Email: Mracuth@gmail.com

## 6) Reviewer Notes Template (binary submission)

Paste and edit:

App purpose: NameSnap is a random name picker for classrooms, giveaways, games, and live streams.

How to use:
1) Paste or type participant names (comma or newline separated).
2) Tap Spin to select a random winner.
3) Optional: enable No-Repeat mode and use Reset when needed.

Privacy: No account, no tracking, and no data leaves the device.

IAP (if included): “Unlimited Contestants” unlock is available from the upgrade/settings area. “Restore Purchases” is supported.
