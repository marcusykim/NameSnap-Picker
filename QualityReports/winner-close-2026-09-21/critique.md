# NameSnap winner-close repair: bounded UI critique

Verdict: ACCEPTED for the close-target repair. No new visual regression or release-blocking close-affordance issue was found in the reviewed states. This is not certification of unrelated winner-screen styling or all celebration variants.

Reviewed the current CSS diff, the three new browser regression cases, and all six original-resolution screenshots in `/tmp/namesnap-winner-close-review/`: desktop, phone, and landscape at approximately 200ms and 4900ms. No tabs/accounts were opened, code was not modified, and tests were not independently rerun.

## Rendered findings

- Desktop (1440×1000): the close button remains in the card's upper-right corner in both captures. The late guitarist overlaps the card's right edge and approaches the button's lower edge, but the X remains visible. Winner name, number, and both main actions remain readable.
- Phone (390×844): the close button is fully inside the viewport and remains in the same location before and after the hero enters its reserved illustration area. Neither hero pose covers the X or either action. The early illustration area is largely empty; this is the existing hero entrance, not a new layout shift.
- Landscape (844×390): the compact card retains visible close, Keep going, and Reset picks actions in both poses. The late right-side hero does not obscure their labels. No new control clipping or text overlap is apparent.

The close glyph is small within its outlined target, but it is identifiable in all six captures. No appearance change to that existing glyph is introduced by this patch.

## Source and behavioral evidence

The CSS change makes `.celebration-hero` decorative for hit testing through `pointer-events: none`. Removing the card's scale/rotate entrance prevents its controls from moving while the user targets them. Hero/confetti animation remains independent of the controls; markup and handlers are unchanged.

The regression cases sample the close target at 80, 200, 650, 1200, 2100, and 4900ms, assert that its center resolves to the close button and stays within one pixel of its original position, then perform an early mouse click or phone tap and assert the modal closes. The parent reports all 17 browser regressions passed. Screenshots establish visibility and layout; these assertions provide the hit-testing and early-dismissal evidence.

## Limits

Visual coverage uses the deliberately wide, right-side guitarist variant. Other hero artwork, browser engines, zoom levels, and open mobile keyboards are not separately pictured. The global decorative hit-testing rule and removed card transform are broader than this visual fixture, but this bounded review does not claim every celebration frame was inspected.
