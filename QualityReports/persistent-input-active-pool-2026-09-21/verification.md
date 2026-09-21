# Persistent input and active-pool duplicate detection

September 21, 2026. Site: https://getnamesnap.web.app.

## Requested behavior

This release supersedes the automatic input-clearing behavior described in
`../session-and-restore-2026-09-21/verification.md`. The user explicitly requested
that the name input remain populated after adding contestants.

- Add names, Cancel, Skip duplicates, Add all anyway, Undo, checkout cancellation,
  and checkout success all preserve the input. Undo removes only the last pool
  additions, without reinserting names into the persistent input.
- Clear this list explicitly clears the input. Clear pool preserves it.
  Explicitly choosing Start a fresh session continues to reset the picker and
  pending checkout names while preserving paid access.
- An active pool of zero does not show a duplicate confirmation, including the
  first submitted batch with repeated names, per the user's zero-pool rule.
- When the active pool is nonempty, confirmation checks the same eligible
  contestants shown by the Active pool counter. Inactive/picked contestants do
  not count. Repeated names within the incoming batch still count. The displayed
  duplicate count and Skip duplicates use this same basis.

## Reproduction and checks

Before the fix, two added browser regressions failed: re-adding a previously
picked name with zero active contestants, and adding a repeated-name first batch
into an empty pool. Both previously triggered the duplicate confirmation.

The independent release review identified a third failing regression: a pick
could finish while its duplicate confirmation was open, leaving a stale dialog
when the active pool became zero. The dialog now renders only while duplicates
remain in a nonempty active pool and discards a stale pending decision. The input
stays intact; pressing Add again works without a warning. The new race regression
failed before this repair and passed after it.

After the fix, all 14 browser regressions passed against the production static
build. Coverage includes desktop and phone input persistence, manual clearing,
fresh sessions, all three duplicate decisions, Undo, continued saved sessions,
checkout cancellation/success, late checkout returns, clearing the pool, and
active versus picked duplicate eligibility. Payment APIs were isolated fixtures;
no payment, email, or account state was submitted by the tests.

The 10 existing build/render tests, ESLint, and the isolated frontend TypeScript
check also passed. Main static assets: `index-BNb5FwQm.js` and
`index-CpsLS4Ps.css`. This change does not modify backend payments or the already
verified Firebase restore-link repair.

## Rendered evidence

The included desktop (1440 x 1000) and phone (390 x 844) captures show retained
editor values after Add. The zero-active before/after pair shows the same input
persisting while the pool changes from zero to one without a modal. The actual
desktop and phone duplicate captures show the revised active-pool wording and
three actions. The duplicate-action test also passed with Add all anyway invoked
at the 390 x 844 phone viewport.

This is a bounded behavior and visual-regression review, not a new art direction
or full design certification. Independent critiques are recorded alongside this
report. The phone screenshot covers the first viewport; desktop screenshots show
the pool rows as well as the editor.

## Release

Visible Firebase identity was verified in the existing canonical NameSnap project
tab before deployment: Marcus Kim, marcuskim1989@gmail.com, NameSnap project.
The manifest was updated to signed-in. No extra project tabs were opened for the
fixture tests.

Frontend-only Firebase Hosting deployment completed successfully for `getnamesnap`
in project `namesnap-picker-6759588637`. Public production HTML returned HTTP 200
and referenced the new JavaScript. Both deployed assets returned HTTP 200 and
matched the tested local build byte-for-byte:

- `index-BNb5FwQm.js`, SHA-256
  `68ca3113306a8a943ae2385e1c536459f56e1bee9e0c0d6409aad123cb7b14a7`
- `index-CpsLS4Ps.css`, SHA-256
  `904eaa6f7a40a46622275d60b86f754ab9aa1f59179a8dd72e11a8eb1944a754`

The production HTML uses `no-cache, max-age=0, must-revalidate`. Existing open
picker tabs need a refresh to load this release. User picker data was not changed
for production verification.
