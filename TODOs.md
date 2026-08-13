# NameSnap TODOs

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
