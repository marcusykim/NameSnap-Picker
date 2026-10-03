# NameSnap App Store release — October 2, 2026

## Result

Released **version 2.0 (32)** through App Store Connect following Marcus's explicit release instruction. The UI shows **2.0 Ready for Distribution**. The API reports **READY_FOR_SALE**.

The release was confirmed around **10:35 PM PDT** on October 2 (verification clock: October 3, 05:36 UTC). The public US storefront lookup immediately afterward still returned **1.0**, its February 25 release date, and the old screenshot filenames. Storefront propagation remains pending; this is separate from the successfully completed developer release.

## Scope and verification

- App: NameSnap Picker, `6759588637`, bundle `com.marcuskim.namesnap`.
- Version record: `af56c748-6d98-4c91-af61-f39abd076cc1`.
- Build: `bb0cff33-4d50-42c2-8373-236f4ce18ce2`, version 2.0, build 32. Build processing was Valid and it was not expired.
- Before release: 2.0 Pending Developer Release; the older 1.0 was Ready for Sale.
- Marcus completed visible Apple sign-in. The initial team was Flake Tech Inc; the team selector was switched to Marcus Kim, `681947275`, whose visible app grid contained NameSnap and whose team link matched `67c52852-b22f-4e49-ad81-df53bf4476fb`.
- Verified NameSnap's selected build was 32 and its current listing included the refreshed screenshots, preview, icon, and corrected review notes.
- Clicked Release This Version, then confirmed the dialog making the iOS app available in **175 countries/regions**.
- Retained the selected **Release update to all users immediately** setting and **Keep existing rating**. No price, product, app binary, metadata or media changes were made during release.
- The release control disappeared and the version's status changed to Ready for Distribution. The post-release API snapshot confirms READY_FOR_SALE.
- The disabled scheduled-release field showed October 2 at 11:00 PM PDT, but the scheduled-release option was not selected. Manual release was selected and completed; the inactive date field does not defer this release until 11:00 PM.

This was publication of the already-approved build. It does not represent new app QA or a newly completed purchase/restore transaction. The remaining bounded QA items in TODOs remain recorded.

## Evidence

- `status-before-release.json`: approved version awaiting manual release.
- `release-confirmed.png`: visible released status with app and account context.
- `release-confirmed.txt`: full browser DOM snapshot after release.
- `status-after-release.json`: post-release App Store Connect API state.
- `public-us-storefront.json`: Apple's public lookup still reporting version 1.0 immediately after the developer release.

[App Store Connect version](https://appstoreconnect.apple.com/apps/6759588637/distribution/ios/version/deliverable)

Apple states that a manually released version [may take up to 24 hours to appear on the App Store](https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/select-an-app-store-version-release-option). The observed difference between the developer release state and public listing is consistent with that propagation delay; a successful public 2.0 download has not yet been verified.
