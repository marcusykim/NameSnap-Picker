# NameSnap TODOs

## Current priorities — updated September 30, 2026

Web status: numeric-name parsing and delayed-draw cancellation fixes are deployed. Bounded stress QA passed 57 automated checks plus interactive desktop/mobile checks; see [the web QA report](QualityReports/web-stress-2026-09-29/QA-REPORT.md).

- [x] **Verify individual picks are accurate.** Both draw modes, modal/history identity, duplicate-name occurrences, no-repeat exhaustion, delayed-result cancellation, and wheel alignment passed the bounded web QA.
- [x] **Verify individual name manipulation is accurate.** Draft edits/deletion, pool addition/deletion, duplicate choices, exact-batch undo, winner exclusion, reset, persistence, and fresh sessions passed. Per-person pool rename/include controls are not exposed by the current web UI; see the report's scope.
- [ ] **Finalize the iPhone app.** Complete app QA, purchase/restore checks, and release preparation.
- [x] **Upload the iPhone test candidate.** Version 2.0 (32) passed archive validation, uploaded to App Store Connect, processed successfully, and is available to the two existing internal TestFlight groups. Public App Store release remains pending.
- [x] **Submit mobile for App Store review.** Version 2.0 (32) resubmitted September 30 at 2:29 PM PDT together with Unlimited Lifetime, Unlimited Monthly, and the subscription group. Apple shows all four items Waiting for Review; release is manual. [Rejection correction and evidence](QualityReports/app-review-rejection-2026-09-30/QA-REPORT.md).
- [ ] **Record Apple's result for the corrected submission.** Submission `c57865bb-3166-4266-80b1-cf9c5740bcc5` is awaiting review. The September 30 information-needed rejection was addressed with current purchase-location steps and screenshots. Approval is pending.
- [ ] **Find 1,000 of the largest Twitch streamers and send personalized NameSnap pitches through accepted business-contact routes.** Updated scope authorized September 29. Preserve ranking/contact provenance and verified send outcomes. The shared email provider currently has no approved cold-email route; accepted pitch forms may be used where appropriate. No campaign sends have occurred.

Campaign checkpoint: three first-party business contacts (shroud, Myth, Summit1G) are verified locally in `artifacts/outreach/2026-09-29`. The 1,000-person ranking export is unfinished: the site's offered CSV action did not return an accessible file through the supported built-in browser. The source prohibits scraping. A client-project agency form was not treated as permission for creator product recommendations. Research notes and one unsent draft are preserved; no messages, replies, or demand are claimed.

### iOS accuracy QA — September 29

- Added 41 passing model/UIKit regression tests and completed simulator and real-iPhone name-operation checks. Fixed numeric-name parsing, winner identity validation, spin cancellation, wheel eligibility, selected-text paste handling, and first-row keyboard focus.
- Build 31 repairs the winner close button's status-area overlap; build 32 removes the confetti GIF's black background and passed the final real-iPhone winner/X check. Final device verification is recorded in [the QA report](QualityReports/ios-name-accuracy-2026-09-29/QA-REPORT.md).
- The two web accuracy tasks above remain separate; iOS checks do not certify the web implementation.
- Remaining release checks include purchase/restore, physical clipboard paste, and the existing main-screen status-area overlap. Other device/layout/accessibility coverage is bounded in the QA report.

### App Review correction — September 30

- Apple could not locate Lifetime under Guideline 2.1(b). Both products still had obsolete review instructions referencing a gear icon and an upgrade menu removed by the UI redesign. The prior submission contained only the app version; the products and subscription group were Developer Rejected.
- Built the unchanged build-32 native source in Release for iPhone 16e. Pasting 17 names and tapping ADD THESE NAMES TO POOL opened the current Unlimited screen, showing Lifetime, Monthly, and Restore Purchases. This checks discovery, not completion of a sandbox transaction.
- Corrected both product review notes and the app-version notes, uploaded a current purchase-screen screenshot to each product and app review, and replied to Apple with the steps and attachment.
- Replaced the incomplete rejected submission with a four-item submission. The Paid Apps Agreement was verified Active; purchase availability is all countries/regions. Existing product IDs, pricing, build 32, updated icon, store screenshots/previews, and manual release remain in place.
- The checked-in `fastlane/review-notes.txt` now preserves the current walkthrough. Listing uploads also preserve manual release.

The release notes below are historical context. Recheck their status before
acting; the list above is the current work queue.

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

### 2. Final monetization model
Status: decided

Locked model:
- Base app is **Free**
- Free tier allows up to **16 contestants for one session**
- Monthly subscription is **$0.99/month** for unlimited contestants
- Lifetime unlock is **$6.99 one-time** for unlimited contestants

Locked product IDs:
- Monthly: `namesnap.unlimited_monthly_099`
- Lifetime: `namesnap.unlimited_lifetime_699`

Important implementation note:
- Remove any other pricing schemes from code/docs/App Store Connect.
- Because App Store Connect products cannot simply be renamed in place, create the new IDs above and retire the old contestant-based IDs.

Why this matters:
- App Store Connect listing, reviewer notes, paywall copy, and customer-facing messaging should now all align to this exact model.
- The Firebase support/privacy/marketing site should stay aligned with the final product, and the underlying monetization decision is now settled.

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

### 4. Maintain the customer-facing Firebase support/privacy/marketing site
Status: live and aligned with the final product

Relevant file:
- `AppStoreMetadata/SUPPORT_MARKETING_PAGE_COPY.md`

Rule:
- The hosted Firebase pages and source copy should reflect the final truth of:
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

## Next Session Checklist

0. Set up the local StoreKit test loop using `STOREKIT_LOCAL_TESTING.md`, attach `NameSnap.storekit` to the `NameSnap` run scheme, and verify paywall/restore/relock behavior locally before leaning on Sandbox again.
1. Create the two final App Store Connect products:
   - `namesnap.unlimited_monthly_099`
   - `namesnap.unlimited_lifetime_699`
2. Archive NameSnap and verify archive/upload readiness.
3. Review `NameSnap/NameSnap/Sounds/SOUND_SOURCES_AND_LICENSES.md` and verify all sound licenses for release.
4. Verify the live Firebase support, privacy, and marketing pages against the final App Store Connect submission details.

## Immediate Next Step

Finish the local StoreKit loop first:
- open `NameSnap/SupportingFiles/NameSnap.storekit`
- add `namesnap.unlimited_monthly_099`
- add `namesnap.unlimited_lifetime_699`
- attach it in `Product -> Scheme -> Edit Scheme... -> Run -> Options -> StoreKit Configuration`
- verify locked >10 names shows the paywall, monthly unlock works, clearing transactions relocks, and restore works

After that, create the final App Store Connect products and move straight into archive validation.

---

## Input editor follow-up — 2026-04-02

Status:
- Backspace behavior is now materially improved and should be preserved.
- Verified working: backspacing from an already-empty row jumps upward without dismissing the software keyboard.
- Verified working: backspacing through a filled row to empty also jumps upward without dismissing the software keyboard.

Open bug for tonight:
- Return-key advance is only partially reliable.
- It usually advances to the next row, but can fail when there is an empty row at least two rows above the current row.
- Tapping directly into the destination empty row and typing works, so the row exists and is focusable; the failure is specific to the Return-key advance path/state.

Constraint for next fix:
- Do not regress the now-working backspace behavior.
- Avoid allowing hidden/lingering empty-row states to destabilize later Return-key advance.
- Likely rule to enforce: an empty row should not be allowed to advance downward via Return.
