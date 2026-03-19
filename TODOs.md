# NameSnap TODOs

Last updated: 2026-03-19 13:06 PDT

## Current App Store Submission Priorities

### 1. Fix signing and provisioning for iPhoneOS Release builds
Status: blocking submission

What we found:
- A real Release build for generic iOS failed.
- Xcode reported that no provisioning profiles were found for `com.marcuskim.namesnap`.
- Automatic signing is currently not getting us across the finish line for this target in CLI release build mode.

Why this matters:
- Until signing/provisioning is resolved, NameSnap is not truly submission-ready.
- This is the highest-priority blocker because it blocks archive/upload flow.

Next actions:
- Inspect Xcode signing configuration for the NameSnap target.
- Confirm team, bundle ID, and profile state.
- Re-run release build once signing is corrected.
- Move to archive validation immediately after the build succeeds.

---

### 2. Lock final monetization model
Status: decision required

Current state:
- Code supports lifetime unlock and monthly unlock via StoreKit.
- App Store prep doc still correctly treats pricing as an open decision.

Decision to make:
- Paid app with no IAP
- Free app with IAP unlock
- Paid app with IAP

Why this matters:
- App Store Connect listing, reviewer notes, and customer-facing copy all depend on this.
- The Notion support/privacy/marketing page should not be finalized until this is decided.

---

### 3. Verify sound licenses before release
Status: release-risk item

Relevant file:
- `NameSnap/NameSnap/Sounds/SOUND_SOURCES_AND_LICENSES.md`

Why this matters:
- The repo explicitly notes that source licenses need verification before App Store release.
- This is the kind of thing that can become an annoying late-stage blocker if ignored.

Next actions:
- Review every sound source listed.
- Confirm license compatibility for App Store release.
- Replace any risky audio asset if needed.

---

### 4. Finalize customer-facing Notion support/privacy/marketing page near the end
Status: waiting on final product + monetization details

Relevant file:
- `AppStoreMetadata/NOTION_SUPPORT_MARKETING_PAGE_COPY.md`

Rule:
- This should be one of the last things updated.
- It should reflect the final truth of:
  - monetization,
  - purchase model,
  - privacy wording,
  - support flow,
  - and app positioning.

---

### 5. Clean repo hygiene noise before final shipping commits
Status: needed

Known local junk observed:
- AppleDouble `._*` files
- Xcode user interface state noise
- `.tmp/`

Why this matters:
- Shipping repo history should stay clean.
- Noise makes release-state auditing harder.

Next actions:
- Keep release-related commits focused on meaningful project files.
- Restore or ignore junk files instead of committing them.

---

## Immediate Next Step

Fix signing/provisioning first. Everything else is downstream of that.
