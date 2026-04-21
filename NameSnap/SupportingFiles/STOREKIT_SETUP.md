# NameSnap StoreKit Local Testing Setup

## Goal
Use a local Xcode StoreKit configuration for fast, resettable purchase testing during development, while keeping Sandbox as the final reality-check before submission.

## Why this exists
Sandbox purchases are sticky and annoying to reset.
Local StoreKit testing is faster, deterministic, and much easier to manage.

## Current product IDs
- Monthly subscription: `namesnap.unlimited_monthly_099`
- Lifetime unlock: `namesnap.unlimited_lifetime_699`

## One-time Xcode setup
1. Open `NameSnap.xcodeproj` in Xcode.
2. Choose the shared `NameSnap` scheme.
3. Create a StoreKit configuration file:
   - `File -> New -> File...`
   - choose `StoreKit Configuration File`
   - save as `NameSnap.storekit`
   - save it at `NameSnap/SupportingFiles/NameSnap.storekit`
4. In the StoreKit editor, create these products:

### Product 1
- Type: Auto-Renewable Subscription
- Reference Name: `Unlimited Monthly`
- Product ID: `namesnap.unlimited_monthly_099`
- Price: `0.99`
- Subscription Group: create one, for example `NameSnap Unlimited`
- Duration: Monthly

### Product 2
- Type: Non-Consumable
- Reference Name: `Unlimited Lifetime`
- Product ID: `namesnap.unlimited_lifetime_699`
- Price: `6.99`

## Wire the scheme to the StoreKit file
1. `Product -> Scheme -> Edit Scheme...`
2. Select `Run`
3. Open the `Options` tab
4. Under `StoreKit Configuration`, choose `NameSnap.storekit`

## Fast local test loop
1. Run the app with the StoreKit config attached.
2. Add more than 10 names.
3. Confirm the paywall appears.
4. Buy Monthly, confirm unlimited unlocks.
5. Use Xcode menu:
   - `Debug -> StoreKit -> Manage Transactions`
   - or `Debug -> StoreKit -> Clear Transactions`
6. Confirm the paywall returns after transactions are cleared.
7. Test `Restore Purchases`.
8. Test Lifetime unlock too.

## Recommended policy
- Default dev loop: local `.storekit`
- Final verification before submission: Sandbox Apple ID

## Notes
- NameSnap currently derives premium state from StoreKit entitlements directly.
- If StoreKit reports a matching entitlement, the app unlocks premium.
- If the entitlement disappears and the app refreshes entitlements, the app should lock back down.
