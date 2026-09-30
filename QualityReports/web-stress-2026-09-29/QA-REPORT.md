# NameSnap web stress QA — September 29, 2026

Production: https://getnamesnap.web.app
Scope: name parsing, individual draft/pool operations, winner identity, no-repeat behavior, delayed draw cancellation, free-tier boundaries, and bounded browser rendering. This is not a real payment transaction or statistical randomness audit.

## Findings and deployed fixes

- Numeric handles were corrupted: `2pac`, `007`, `50 Cent`, and `7-11` lost leading digits. The parser and staged editor now remove only explicit numbered-list prefixes with punctuation and following whitespace.
- Pending Quick Pick and wheel callbacks could announce a removed contestant after clear, reset, delete, or undo. Ten baseline regression cases failed before the fix. Pool mutations and mode changes now cancel pending callbacks through a generation token and timer cleanup.
- Two synchronous spin triggers could commit two results. A synchronous spin lock now admits one draw until completion or cancellation.
- No visual layout, checkout pricing, or payment-worker behavior changed in this deployment.

## Automated verification

57 checks passed:

- 29 checkout-worker tests use mocked Stripe and in-memory SQLite. These cover concurrent checkout starts, active-purchase blocking, expiry/replacement, completion/webhooks, and entitlement/restore paths without creating actual charges.
- 18 production-parser/callback tests cover numeric/Unicode names, numbered/comma/CRLF input, a 10,000-name round trip, duplicate handling, distinct entry identities, restore validation, both draw modes' mutation races, one-result locking, and repeat-mode eligibility.
- The wheel test checks 2,007 combinations of segment count, selected index, and prior rotation, including pools of 500 entries. The actual production callback must align the chosen segment center with the top pointer and commit the same contestant's name, number, and ID.
- 10 rendered-HTML/SSR checks passed.
- ESLint, the static production build, and `git diff --check` passed. Existing headless browser test scripts were not run; interactive browser tests used Computer Use.

## Interactive browser evidence

Tests used the separate localhost origin and disposable names. The production saved list was only reopened and inspected after deployment.

- Pasted `2pac`, `007`, `50 Cent`, `7-11`, `Zoë`, `李雷`, `Alex`, `Alex`; input and pool preserved the exact names.
- Adding the initial duplicate-containing draft to an empty pool produced no duplicate confirmation. Input persisted after Add.
- A real wheel draw was canceled by clearing the pool during its delay. No stale winner/history appeared after the deadline; the draft remained.
- Re-added to the empty pool without a stale duplicate warning. Actual wheel and Quick Pick draws selected the two Alex entries independently (#7 and #8).
- Exhausted the remaining six entries with actual Quick Pick draws. Each modal name/number matched the original numbered roster; numbers 1–8 appeared exactly once. The X dismissed each of these six reveals immediately. `live-draw-results.json` records the observed draws.
- Re-adding after exhaustion produced no duplicate prompt and added eight new entries. Undo removed exactly that batch, leaving the eight original consumed entries and unchanged draft.
- Reset restored eight eligible entries and cleared history. Confirmed deletion of the first Alex left the other Alex, renumbered to #7, with all six neighbors unchanged.
- Editing draft `Zoë` to `Zoe Updated` and deleting draft `2pac` did not change the active pool. Clearing the draft left the pool intact.
- A genuine duplicate dialog reported six duplicates for the edited seven-name draft. Cancel changed nothing; Skip added only `Zoe Updated`; Add All added seven separate entries. Undo restored the original seven-entry pool in both cases.
- Pasted 1,000 sequential names through the actual editor. All 1,000 values and order matched the input. Attempting Add opened upgrade without changing the existing seven-entry pool; dismissing preserved the draft.
- Reload offered the saved state. Starting a fresh session cleared draft, pool, and history. The 16-name free boundary accepted all names without a duplicate warning. Adding the seventeenth held it in the draft, opened upgrade, and left the 16-entry pool unchanged.
- At 390×844, inspected the actual winner rendering and immediately dismissed another reveal with its X. `mobile-winner.png` and `mobile-dismissal.json` record this bounded viewport check.

## Deployment

Firebase Hosting deployment to `namesnap-picker-6759588637`, site `getnamesnap`, completed after visibly verifying the owning Google account. The deployed JavaScript and CSS exactly match the local production build; hashes are recorded in `deployed-asset-verification.json`. The production browser loaded successfully with its saved 16 contestants and one prior winner preserved, leaving 15 eligible contestants. No production pool was cleared or modified for this pass.

## Boundaries

Real Stripe payments, email-link redemption, different browser engines, assistive technology, a paid 10,000-entry DOM/pool, and random-selection distribution remain outside this pass. Per-person editing is a draft operation in the current web UI; adding creates separate pool entries. The UI has per-person pool deletion, while no-repeat draws manage winner exclusion. This report does not claim an individual pool rename/include toggle that the interface does not expose.
