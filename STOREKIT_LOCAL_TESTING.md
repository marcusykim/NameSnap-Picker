# NameSnap Local StoreKit Testing

Use this as the default purchase-testing path during development. The goal is to replace sticky Sandbox-account iteration with a fast, resettable local StoreKit loop.

## Products to create in the StoreKit configuration file

Create a new **StoreKit Configuration File** in Xcode and save it as:
- `NameSnap/SupportingFiles/NameSnap.storekit`

Inside that file, add exactly these products:

### 1. Monthly Unlimited
- Type: **Auto-Renewable Subscription**
- Product ID: `namesnap.unlimited_monthly_099`
- Display name: `Unlimited Monthly`
- Price: `$0.99`
- Subscription group: create one group, for example `NameSnap Unlimited`

### 2. Lifetime Unlimited
- Type: **Non-Consumable**
- Product ID: `namesnap.unlimited_lifetime_699`
- Display name: `Unlimited Lifetime`
- Price: `$6.99`

These IDs must stay aligned with `NameSnapPurchaseManager` in `NameSnap/ContentView.swift`.

## Attach the StoreKit file to the NameSnap run scheme

The shared `NameSnap` scheme already exists in the repo. The remaining Xcode click-path is:

1. Open `NameSnap.xcodeproj`
2. Choose the `NameSnap` scheme
3. Go to **Product → Scheme → Edit Scheme…**
4. Select **Run**
5. Open the **Options** tab
6. Under **StoreKit Configuration**, choose `NameSnap.storekit`

This scheme attachment is the only part intentionally left as an Xcode-side operation because it can be stored in user/scheme state.

## Daily test loop

Use this loop for normal monetization work:

1. Launch NameSnap with the local StoreKit file attached
2. Add more than 10 names
3. Confirm the paywall appears
4. Purchase **Monthly Unlimited** locally
5. Confirm adding more than 10 names now works
6. Use **Debug → StoreKit → Manage Transactions** or **Clear Transactions**
7. Relaunch and confirm the paywall appears again
8. Test **Restore Purchases**
9. Repeat for **Lifetime Unlimited**

## Keep Sandbox, but only as the final external check

Recommended split:
- **Local StoreKit file** for day-to-day iteration
- **Sandbox Apple ID** for final reality-check testing before submission

Why:
- local StoreKit is faster and resettable
- Sandbox is closer to Apple’s real environment, but much stickier and harder to reset

## Sandbox cleanup fallback

If a Sandbox tester still has sticky entitlements, do the minimum necessary:

1. Delete the app from the simulator/device
2. Sign out of the Sandbox account if needed
3. Prefer switching back to the local StoreKit file for normal testing
4. Use a fresh Sandbox tester later for one final external verification pass

## Current app behavior to verify with local StoreKit

The paywall gate currently checks the add flow before importing names into the pool:
- if `isUnlimitedUnlocked == false`
- and the proposed total would exceed `10`
- then the upgrade modal should appear

So the critical local verification cases are:
- locked user, >10 names, paywall appears
- unlocked user, >10 names, import succeeds
- cleared transactions, paywall returns
- restore re-unlocks when appropriate
