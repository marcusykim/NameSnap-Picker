# Picker draft and restore-link repairs

September 21, 2026. Site: https://getnamesnap.web.app.

## Picker state

Reproduced the stale-draft problem: adding Alex and Jordan left both names in
the editor. Appending Casey and pressing Add names then resubmitted Alex and
Jordan, showing a duplicate warning. A first unique add immediately after
Start a fresh session did not reproduce the warning in the tested flow.

Successful adds now consume the draft. Cancel preserves a real duplicate draft;
Skip duplicates consumes the submitted batch, including an all-duplicate batch;
Add all anyway remains available. Undo restores the added names ahead of any
new unsubmitted draft.

Starting fresh removes pending checkout names and their submitted-draft snapshot
as well as picker state. Paid access stays separate. A successful checkout clears
only a draft that still matches its submitted snapshot, preserving newer edits.

Eight Playwright regressions passed against the production static build:
desktop/phone batches and fresh starts, real duplicate decisions, Undo, saved
session continuation, free-limit cancellation and paid return, fresh-session
queue clearing, and preserving a newer draft on a late checkout return.

## Restore-link root cause and live proof

The default Firebase hostname had a catch-all permanent redirect to the new
website. Its `/__/firebase/init.json` request returned HTTP 301 to the other
origin, preventing the hosted Firebase email action handler from loading its
configuration. The visible result was only “Error encountered,” before any
email-link sign-in request reached Firebase Authentication.

The retired-host redirect now excludes Firebase's reserved namespace while
preserving public-page paths. After deployment, the configuration endpoint and
email action page returned HTTP 200 on the original origin; `/`, `/support`,
`/privacy`, and asset paths still redirected to the production website.

The user's already-open failed email link was reloaded with the browser cache
bypassed, using the same canonical NameSnap profile and existing tab. It reached
NameSnap, the Firebase email-link sign-in request returned HTTP 200, and the page
visibly showed the expected purchase email and “Monthly access is active.”
The live purchase-status request also returned HTTP 200. No sign-in codes,
authentication storage, credentials, or authentication response bodies were
read, copied, or saved. No replacement email or payment was submitted.

Firebase identity before deployment: the existing console visibly showed the
expected project and marcuskim1989@gmail.com. The retired site is
`namesnap-picker-6759588637`; the main site is `getnamesnap`, both in project
`namesnap-picker-6759588637`.

## Other checks

- Ten existing build/render tests passed after replacing the catch-all redirect
  assertion with public-route and reserved-authentication-route cases.
- ESLint and isolated frontend TypeScript checking passed.
- Production static build passed; main frontend assets are
  `index-BomtHt0a.js` and `index-CpsLS4Ps.css`.
- The payment worker and database schema are unchanged by this release.
- Original-resolution desktop and phone inspection found no visual regression
  in the affected journey. This is a bounded behavior review, not a redesign.

## Reference

Firebase documents its [reserved Hosting URLs](https://firebase.google.com/docs/hosting/reserved-urls)
and the [email-link sign-in flow](https://firebase.google.com/docs/auth/web/email-link-auth).
Live routing and account restoration were verified separately as described above.
