# Checkout replacement across browsers

Released September 20, 2026 to `namesnap-web-payments` version
`27f3d099-cd83-4fd0-b101-0ca90647b6f9`.

## Problem and behavior

An unpaid checkout reserved the email for its original browser, producing
“A checkout for this email is already open” when the customer tried elsewhere.
Another browser can now start checkout with that email immediately. The worker
expires the old unpaid Stripe session before creating a replacement with the
new browser's ownership metadata and a separate Customer. Same-owner retries
can reopen the existing checkout URL. Starting elsewhere does not disclose the
old browser's checkout URL, saved billing information, or paid access.

The latest replacement is payable. Older replaced payment pages expire. This
uses Stripe's documented [Checkout expiration behavior](https://docs.stripe.com/api/checkout/sessions/expire):
expired sessions cannot be completed. It avoids allowing multiple payable
sessions and trying to refund duplicate charges afterward.

If payment beats expiration, the worker retrieves the current Stripe state,
fulfills the completed purchase, and blocks a duplicate. A payment already in
processing must resolve before another collectible checkout is created.
Conditional reservation writes prevent delayed responses from overwriting a
newer checkout. Stripe idempotency conflicts retry with the same persisted
parameters. The existing 23-hour uncertain-response recovery limit remains.

## Validation

- All 29 payment tests passed against real in-memory SQLite migrations, mocked
  Stripe requests, Firebase JWT verification, and signed webhooks.
- Added coverage for different browsers replacing checkout, concurrent starts,
  lost/late creation responses, expiration races won by paid or processing
  payments, already-expired sessions, failed expiration, and Stripe idempotency
  contention. Only one unpaid session remains payable after replacement.
- Tests verify that the new payer can confirm their purchase while the original
  browser cannot gain access from knowing the email. Existing duplicate-purchase,
  restoration, subscription cancellation, and lifetime-upgrade tests still pass.
- Strict worker TypeScript check, ESLint, and Wrangler deployment dry-run passed.
- No frontend or database migration was required.

## Live verification

Two consecutive calls to the deployed checkout endpoint with different,
newly generated browser identities and the same purchase email both returned
HTTP 200 with distinct Stripe checkout URLs. No existing browser identity or
session storage was read or copied.

The existing canonical NameSnap browser tab then opened another Lifetime
checkout through the actual site. Stripe displayed NameSnap Unlimited Lifetime
at $6.99. Choosing the visible Pay without Link option reached the regular
payment form. No Pay or Subscribe action was submitted. This verifies checkout
opening and replacement, not a real payment or refund.

The browser was returned to NameSnap's purchase choices with one website tab.
The previously reviewed product UI was unchanged; no new design approval is
claimed by this backend follow-up.
