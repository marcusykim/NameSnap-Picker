# NameSnap active-pool behavior: bounded UI critique

Reviewed the screen-design-quality-gate critical rubric, the eight supplied screenshots at original resolution, the current source diff, and the relevant browser regression cases. No code was modified and no browser tabs or accounts were opened. This is a behavior regression review of the existing art direction, not a new design certification.

## Changed behavior

Accepted within the requested input/duplicate scope. No concrete regression was found in the changed behavior.

- `desktop-added.png` and `phone-added.png`: Alex/Jordan remain in the input after addition. The input count is two, the active-pool count is two, and the desktop wheel has two matching eligible contestants. Add names remains available, consistent with preserving the reusable input.
- `desktop-fresh.png` and `phone-fresh.png`: screenshots show Alex/Jordan added after a fresh start, rather than the immediate empty state. The retained input and resulting two-item pool agree. Fresh-start emptiness is checked in the test source.
- `actual-duplicate.png`: the modal states that adding the list creates two duplicates in the active pool. Cancel, Skip duplicates, and Add all anyway are distinct and readable; the modal is fully inside the desktop viewport without overlapping actions.
- `actual-duplicate-phone.png`: at 390×844, the duplicate modal is fully visible with readable wrapped copy and three separate, full-width actions. Cancel, Skip duplicates, and Add all anyway have no clipping or overlap. The parent reports that the focused phone test successfully clicked Add all anyway.
- `zero-active-before-add.png` to `zero-active-added.png`: the existing picked Alex remains struck through; adding the retained input produces a new eligible Alex row and changes the active count from zero to one. The input remains intact and no duplicate modal obstructs this transition.

Source inspection agrees with these states: confirmation is gated on a nonempty `activeEntries` set, and duplicate counting plus Skip duplicates use that same set. Repeated incoming names are checked only when the active pool is nonempty. Normal add, undo, and checkout completion retain the input under the latest requested behavior.

## Existing visual inconsistency, separate from this diff

The Quick Pick hero still shows **NEXT UP — 1. Alex** in `zero-active-before-add.png`, despite **Waiting for contestants**, active pool zero, and Alex being struck through as already picked. After re-add, the eligible pool row is **2. Alex**, while the hero still shows **1. Alex**. This appears to be stale result labeling rather than a new duplicate-handling regression. Label the retained result as the previous pick, or show an appropriate ready/empty state, if this existing display behavior is addressed separately.

## Visual and verification limits

No new clipping, overlapping controls, unreadable modal actions, or layout drift was found in the reviewed captures. The established mobile stack continues below the 844px viewport, so its pool rows and reveal stage are not visible in the phone picker captures. The phone duplicate-modal limitation is closed by the additional 390×844 render; a phone zero-active transition was not supplied. Screenshots alone do not prove absence of a transient modal or keyboard behavior; the corresponding browser tests supply those behavioral assertions and were read, not independently rerun.

Verdict: accept the input persistence and active-pool duplicate behavior. Keep the stale Quick Pick hero labeling documented as an existing component-state limitation. This verdict does not certify the entire picker design or live deployment.

## Follow-up: pending-pick duplicate race

Reviewed the final render gate/effect and `zero-active-after-pending-pick.png` at original resolution. The new capture shows active pool zero, retained Alex input, a disabled pick action, and no stale duplicate modal after the pending pick completes. Source now requires both a nonempty active pool and a positive current duplicate count to render the modal, and clears the pending decision when either condition disappears. The retained input remains available for the user's next Add action.

The new browser regression reproduces Add during a pending sole-contestant pick, completes the winner flow, asserts the modal is gone at active zero, and successfully adds again without a warning. The parent reports all 14 browser regressions and 10 build/render tests pass, plus lint and TypeScript checks; this reviewer did not rerun them or open tabs.

The reproduced stale-modal race is resolved in the inspected source and rendered state. Bounded acceptance stands with no additional concrete finding. The pre-existing Quick Pick hero-label inconsistency remains outside this patch, as documented above.
