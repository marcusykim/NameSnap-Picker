# NameSnap picker session-state review

Scope: independent review of the existing picker and the small draft/session fix. No art-direction or layout change was requested. Reviewed all five refreshed screenshots at original resolution and the source diff plus eight browser regression cases. Browser tests were read, not rerun, and no tabs or accounts were opened.

## Resolved finding

**The checkout-return draft-loss issue is repaired.** Checkout start persists the submitted draft in `namesnap.web.pending-upgrade-draft.v1`. Completion uses a functional state update to clear only an unchanged draft matching that snapshot; newer or edited input remains. Starting fresh removes both queued names and the snapshot. The new browser regression covers canceled checkout, replacement with a new unsubmitted name, and completion of the original checkout, asserting that the newer draft survives. Retaining edited input is a conservative choice; genuine duplicates remain subject to the existing duplicate choices.

## Rendered evidence

- `desktop-added.png`: editor is empty, counter says 0 ready to add, Add names is disabled, and the three-item pool agrees with the three eligible wheel segments.
- `phone-added.png`: the same empty-draft and three-item pool state remains readable at 390px width. The existing vertically stacked layout requires scrolling to reach the pool/wheel; this is not introduced by the fix.
- `desktop-fresh.png` and `phone-fresh.png`: captures are after starting fresh **and then adding Alex/Jordan**, not the immediate empty state. Their two-item pool and empty editor agree. The test source separately asserts the pool is empty immediately after starting fresh.
- `actual-duplicate.png`: the dialog states one duplicate and exposes distinct Cancel, Skip duplicates, and Add all anyway actions with readable labels and no overlap.

## Source and test assessment

Normal successful adds now consume the editor draft. Cancel preserves genuine duplicate input; Skip clears the submitted batch, including an all-duplicate batch. Undo restores the most recent added names ahead of newer unsent input. Starting fresh removes the checkout queue and submitted-draft snapshot as well as picker state while preserving purchase identity/access. Eight supplied browser cases cover these paths, including preservation of a newer draft on checkout return. The parent reports all eight pass.

## Verdict

ACCEPTED for this bounded session-state fix. No remaining concrete regression or critical pixel defect found within the changed journey. This review does not constitute a redesign, blanket approval of the existing picker, or live checkout/email validation.
