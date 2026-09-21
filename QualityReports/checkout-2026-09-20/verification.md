# Email-first web checkout

Implemented September 20, 2026 for the purchase flow at https://getnamesnap.web.app.

## Release status

The frontend and payment worker are deployed. **Live checkout opening passed**
for both $6.99 Lifetime and $0.99/month Monthly, with the purchase email carried
into Stripe's payment form. Both flows reached the regular payment form without
email-link authentication. No payment was submitted or charged.

The initial smoke test exposed HTTP 403 for `POST /v1/customers`. With Marcus's
explicit approval, Customers changed from None to Write on the existing
“NameSnap web payments runtime” restricted key in the visibly verified SideQuest
Software Stripe account. A comparison of permission selections confirmed that
Customers was the only changed resource. Saving the setting resolved the error;
both subsequent live Checkout sessions opened successfully.

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

## Live verification details

- Lifetime displayed “NameSnap Unlimited Lifetime”, $6.99, and the purchase email.
- Monthly displayed “Subscribe to NameSnap Unlimited Monthly”, $0.99 per month,
  and the same purchase email. Switching plans expired the earlier open checkout.
- Stripe offered optional Link verification for the existing email. Choosing
  “Pay without Link” opened the regular payment form without accessing saved
  payment information or entering a verification code.
- Returned the browser to NameSnap's purchase choices after verification.
- A real charge and real recovery-email delivery were not performed.

## Browser cleanup

The NameSnap launcher still included the retired Firebase hostname. Because that
URL redirects to getnamesnap.web.app, every lease-wrapper launch reopened it.
Updated only NameSnap's website URL in the live project registry and platform
manifest to the canonical hostname, deduplicated that project's launch URLs,
and synchronized the browser runtime. Duplicate NameSnap root-page tabs were
closed while preserving the current purchase screen and all account tabs.
