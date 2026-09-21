# NameSnap persistent input and active-pool duplicates — release critique

Reviewed September 21, 2026. **PASS for the bounded behavior release after the race repair. No new release-blocking defect remains in the reviewed patch.** This is a behavior and rendered-regression review of the existing design, not full design certification.

## Finding resolved during review

**Resolved P2 — A pending duplicate dialog could outlive the last active contestant and show zero duplicates.** I identified the uncovered sequence from source: with one active Alex and retained input Alex, start Quick pick and immediately press Add names. The duplicate dialog opened against one active contestant; completion then excluded Alex without clearing the pending decision. After dismissing the winner overlay, the zero-count duplicate dialog could remain. The parent reproduced this with a failing browser regression.

The repaired renderer requires both a nonempty active pool and a positive duplicate count, and an effect clears the pending request when either condition stops applying. Input is untouched. I reviewed both changes and the added regression. The new `zero-active-after-pending-pick.png` visibly shows active pool zero, retained Alex input, and no duplicate dialog after the pending pick. The regression also verifies that pressing Add again creates one active entry without a warning. This resolves the observed semantic and journey defect without changing the requested persistent-input behavior.

## Evidence that does hold

- Desktop and phone added renders visibly retain Alex and Jordan in the input, keep Add names and Clear this list enabled, and show two active contestants. The count and persistent editor agree with the new requirement.
- The zero-active before/after images retain Alex in the input while the active count changes from zero to one. The previously picked Alex remains struck through, the new entry is active, and no duplicate dialog appears.
- The desktop and phone duplicate dialogs use the same active-pool wording and visible Cancel, Skip duplicates, and Add all anyway actions. Two duplicate names match the fixture's retained Alex/Casey input. No new clipping or overlapping app controls appears in the supplied views.
- Initial detection, displayed duplicate count, and Skip duplicates all use `activeEntries`. That collection is also used by the Active pool counter and excludes picked contestants while No repeats is enabled. The explicit nonempty guard lets an empty active pool accept even a repeated-name first batch, as requested.
- Add, Skip, Add all, Undo, and checkout success no longer modify input. Manual input clearing remains explicit; fresh-session reset still clears picker state and both pending queue keys. Late checkout return preserves edited input because it no longer writes input at all.

## Test assessment and scope

Read the screen-design-quality-gate skill, current implementation/test diffs, the browser regression file, and `QualityReports/persistent-input-active-pool-2026-09-21/verification.md`. Inspected all five requested PNGs plus `actual-duplicate-phone.png` at original resolution, then reviewed the repaired source and new `zero-active-after-pending-pick.png`, with refreshed phone input/dialog renders. I also ran `git diff --check` successfully. No code edits or browser/account actions were performed.

The final 14 browser cases make concrete pool/input assertions for persistence, manual clearing, duplicate decisions, Undo, restore/checkout transitions, zero-active batches, clearing the pool, inactive names while others remain active, and the reproduced eligibility-change race. The parent reports all 14 browser tests, 10 build/render tests, lint, and isolated TypeScript passing after the repair, with static asset `index-BNb5FwQm.js`. This critic inspected their assertions and source paths rather than claiming a second test run. Payment APIs are fixtures; no live payment or account behavior is certified here.

The final supplied pixels and state transitions support the updated requirements. Persistent input, active eligibility, duplicate copy/count, the three decisions, manual clearing, and explicit fresh reset now agree within the reviewed scope.
