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

### 2. Final monetization model
Status: decided

Locked model:
- Base app is **Free**
- Free tier allows up to **10 contestants for one session**
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
- The Notion support/privacy/marketing page should still be finalized near the end, but the underlying monetization decision is now settled.

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

## Next Session Checklist

1. Create the two final App Store Connect products:
   - `namesnap.unlimited_monthly_099`
   - `namesnap.unlimited_lifetime_699`
2. Archive NameSnap and verify archive/upload readiness.
3. Review `NameSnap/NameSnap/Sounds/SOUND_SOURCES_AND_LICENSES.md` and verify all sound licenses for release.
4. Finalize App Store Connect submission details and only then paste the final Notion support/privacy/marketing page copy.

## Immediate Next Step

Create the final App Store Connect products, then move straight into archive validation.
