# Email-first web checkout

Implemented September 20, 2026 for the purchase flow at https://getnamesnap.web.app.

## Release status

The frontend and payment worker are deployed. **Live checkout remains blocked:**
Stripe returned HTTP 403 for `POST /v1/customers` during the browser smoke test.
The purchase dialog displays the payment service error; it did not reach hosted
Stripe Checkout. No payment was attempted or charged.

Approval has been requested to enable Customers: Write on the existing restricted
Stripe key used by the NameSnap worker. Do not describe this release as a working
end-to-end checkout until that permission is verified and a live session opens.

## Behavior

- An email is required before either plan opens Stripe Checkout. Email-link
  authentication is reserved for restoring a purchase on another browser.
- Lifetime remains $6.99 once; Monthly remains $0.99 per month.
- A new Stripe Customer locks the supplied email without exposing another
  customer's saved billing details through an unverified email lookup.
- Only a paid Checkout receipt or matching verified recovery identity unlocks
  access. Browser-only access survives refresh and remains separate from picker
  data and Start Fresh.
- Email and owner reservations prevent concurrent sessions. Persisted parameters
  make uncertain responses safe to retry. Unknown attempts older than 23 hours
  require support recovery before another payable session can be issued.
- Existing monthly/lifetime ownership and subscription events are reconciled to
  avoid duplicate purchases, stale cancellation, or lifetime downgrade.
- The payment return has an explicit confirmation state; active access has a
  visible banner. Privacy text matches the new data flow.

## Validation

- 21 payment tests pass using real in-memory SQLite migrations and mocked Stripe,
  Firebase JWT verification, and signed webhook delivery. Includes wrong-browser
  access, unpaid/canceled sessions, duplicate and concurrent attempts, restore,
  subscription changes, uncertain responses, and idempotency-key eviction.
- 10 existing build/render tests pass, including privacy and picker-state checks.
- ESLint, static export, isolated frontend TypeScript checking, isolated strict
  payment-worker TypeScript checking, and Wrangler dry-run passed.
- The repository-wide TypeScript command has pre-existing unrelated scaffold
  errors in database/runtime declarations and Vite configuration imports.
- Browser checks cover phone (390x844), tablet (768x1024), desktop (1440x1000),
  invalid email without a checkout request, keyboard focus/Space/Escape behavior,
  cancellation, loading, API error, restore sent/expired, and payment-return UI.
- Restore and payment-success screen renders use fixture responses. They are not
  evidence of a real delivered email or paid transaction.
- Independent release pixel review: PASS, 93.7/100, validator passed. See
  `release-screen-quality-report.json` and `release-critique.md`.

## Deployment identifiers

- Firebase project: `namesnap-picker-6759588637`; Hosting site: `getnamesnap`.
- Live frontend assets: `index-KuF8CHaT.js`, `index-Cd4GiRi7.css` (verified from
  the production HTML after the final deployment).
- Worker: `namesnap-web-payments`.
- Worker version: `2c8a424d-c71e-4e27-806e-793d54da2860`.
- D1 migrations `0003_email_checkout.sql` and `0004_checkout_recovery.sql` applied
  remotely. There were zero checkout reservations before migration 0004.

## Remaining acceptance check

Verify the correct Stripe account and restricted key, resolve the customer-create
permission failure, and open a live hosted checkout showing the selected price
and purchase email. Stop before payment. A real charge and email-delivery test
require separate explicit scope; neither was performed here.
