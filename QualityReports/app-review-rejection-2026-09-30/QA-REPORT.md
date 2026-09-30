# App Review rejection correction — September 30, 2026

## Result

Version 2.0 (32), Unlimited Monthly, the Unlimited subscription group, and Unlimited Lifetime were submitted together at **2:29 PM PDT**. App Store Connect shows **Waiting for Review** for the submission and all four items.

New submission: `c57865bb-3166-4266-80b1-cf9c5740bcc5`.
Build: `bb0cff33-4d50-42c2-8373-236f4ce18ce2`, 2.0 (32).
Public release: manual, approval pending.

## Rejection and cause

Apple's September 30, 4:48 AM message on `0681ac05-10a6-451c-9990-403c899cfa5d` invoked Guideline 2.1(b), Information Needed: the reviewer could not locate NameSnap Unlimited Lifetime and requested the steps to reach the purchases.

Visible account identity was Marcus Kim, owning NameSnap Picker, app ID 6759588637. The Paid Apps Agreement was Active. Both purchase products were available in all countries/regions. The Lifetime, Monthly, and subscription-group records were Developer Rejected; the rejected September 29 submission contained only the app version.

Both product review-note fields instructed the reviewer to tap a gear icon, then Upgrade to NameSnap Unlimited. That route is absent from the redesigned build. The app's purchase screen is reached by attempting to add more than the 16-name free limit.

## Corrections

- Saved current, explicit 17-name instructions in Lifetime and Monthly review notes.
- Uploaded `build32-unlimited-screen.png` as each product's review screenshot. Completed upload produced new review screenshot records: Lifetime `48954328-99ca-470d-9f15-d8bb0a3934a3`; Monthly `b7aa5895-ac7f-4f97-8f54-42fb43dbe6fb`.
- Saved the full walkthrough in the app-version Notes field and attached the same current screenshot. Uploading the app attachment refreshed the form and discarded the initially unsaved notes; the notes were filled and saved again afterward, then verified in the ready-for-review view.
- Sent Apple the corrected walkthrough and screenshot. The visible message appeared as Marcus Kim, Today 2:24 PM. Its exact text is recorded in `apple-response.txt`; the confirmation screenshot and observation note are `apple-response-confirmed.png` and `.txt`. After cancellation, the removed submission's details page stopped displaying the Messages section. The saved screenshot records the confirmation before cancellation.
- Canceled the incomplete rejected submission after replying, then submitted the unchanged app version with both products and the subscription group in one draft. This addressed the App Store Connect validation requiring first purchases of each type, and the first subscription group, to accompany an app version.
- Added checked-in `fastlane/review-notes.txt` and made the listing lane read it. Changed the listing lane's automatic release setting to false, consistent with the selected manual-release workflow.

No native or web product source changed. No new binary was needed for the requested information correction. Existing store listing media and icon were retained.

## Verification

- `git diff 08ce5cf..HEAD -- NameSnap NameSnap.xcodeproj` was empty, confirming native source/configuration matched the build-32 release commit.
- Built Release for iPhone 16e / iOS 26.3 with no Debug fixtures or simulated entitlement overrides. Build succeeded; log: `build32-release-simulator.log`.
- Launched from the normal app screen with an empty contestant list. Pasted the supplied 17 names through Simulator UI. The input showed 17 READY and individual numbered rows. Although the clipboard tool reported a timeout, the subsequent UI state confirmed that the paste had completed, so it was not repeated.
- Tapped ADD THESE NAMES TO POOL through Simulator UI. The Upgrade to Unlimited? modal appeared with Unlock Lifetime $6.99, Or Monthly $0.99, Restore Purchases, Privacy Policy, and Terms of Use.
- Captured and inspected the actual screen at original scale. This is functional review evidence, not a new product design or a full visual/accessibility approval. No UI art direction or styling was changed. The existing dense modal/Restore divider and broader accessibility coverage remain outside this information-needed correction.
- Ruby syntax check for `fastlane/Fastfile` passed; `git diff --check` passed.
- Visible App Store Connect success: 4 Items Submitted. The new details page shows all four Waiting for Review, and the unchanged 2.0 (32) build. Proof: `resubmission-confirmed.png` and `.txt`.

This session did **not** complete a StoreKit sandbox purchase or restoration. Product discovery, configuration, metadata persistence, submission grouping, and review submission are the verified scope. Apple approval and public release are pending.

## Evidence

- `apple-rejection.png`: original rejection; `.txt` is a reconstructed observation note from that session, not a fresh capture of the removed submission.
- `build32-unlimited-ax.txt` and `build32-unlimited-screen.png`: current release purchase-screen path.
- `product-review-notes.txt`: corrected product walkthrough.
- `apple-response.txt`, `apple-response-confirmed.txt` / `.png`: sent reply and attachment.
- `combined-draft-before-submit.png`: app and three purchase-related items in one draft.
- `resubmission-confirmed.txt` / `.png`: all four items Waiting for Review.
- `submission-before-resubmit.json`, `submission-after-resubmit.json`: release API status checkpoints.

## Apple documentation used

- [Submit an In-App Purchase](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase/): first purchase of each type and a new subscription group must accompany an app version; all items must be added to the same draft.
- [Manage unresolved issues](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/manage-a-submission-with-unresolved-issues/): a submission with unresolved issues cannot have more items added.
- [Reply to App Review messages](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/reply-to-app-review-messages/).
