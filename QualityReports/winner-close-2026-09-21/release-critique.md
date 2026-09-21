# NameSnap winner X — independent release critique

Reviewed September 21, 2026. **PASS for the bounded interaction repair. No actionable new defect found.** This is not a redesign or full design certification.

## Independent assessment

- The removed card entrance animated the ancestor of the X with scale and rotation. Removing that animation eliminates its contribution to the button's changing position from initial display onward; the unused keyframes are also removed. No delayed enabling or alternate close handler was introduced.
- `pointer-events: none` is applied to the shared decorative `.celebration-hero` image class. Its higher stacking position can therefore no longer capture mouse or touch over the card. The other decorative layers already ignore pointer events, and none of the inspected hero variants or responsive rules overrides that behavior. Applying this only to the decoration preserves the real modal controls.
- X still calls the existing `dismissWinner` handler. That handler stops audio, clears the automatic-dismiss timer, and closes the winner/celebration state without modifying draft or pick history. The delayed focus timer is cleaned up when the winner closes. The patch contains no application-state changes.

## Rendered evidence

Inspected all six supplied PNGs at original resolution: early and late desktop (1440×1000), phone (390×844), and landscape (844×390).

The X occupies the same visible corner in each early/late pair. At the late desktop pose, the wide guitarist overlaps the card's right edge—the important interception case—but the close control remains identifiable. Phone and landscape controls remain inside the viewport, and the winner, number, Keep going, and Reset picks remain legible. No new clipping, missing action, or changed winner content is visible. The early phone view has the expected reserved space before the decorative hero arrives; the card and X are already present.

## Test assessment

The three new viewport cases use a deterministic wide right-side hero, inspect target coordinates and `elementFromPoint` at 80, 200, 650, 1200, 2100, and 4900ms animation poses, and require less than one pixel of position change. They then set the 200ms pose and send a raw mouse click or phone touchscreen tap, avoiding a locator click that might silently wait for animation stability. Assertions require the modal to disappear while Alex remains in the input and the completed no-repeat pick remains inactive. These checks directly address both reported failure mechanisms.

The parent reports the three cases failed before the fix and that all 17 browser cases, 10 build/render tests, lint, and static build now pass. I inspected the test and source paths rather than rerunning browser tests; I independently ran `git diff --check`, which passed. No code edits or browser/account actions were performed.

Coverage is appropriately bounded: the visual fixture uses Alex and one wide hero, the portrait phone exercises touch, and landscape exercises mouse/hit-testing. The tests seek CSS animation poses rather than proving every wall-clock instant or every device/browser combination. The shared CSS repair has no remaining time-dependent input-blocking rule in the reviewed path, so these limits do not block this release.
