# iPad App Store presentation — first independent pass

Date: 2026-09-29. Status: **REPAIR REQUIRED; not approved for upload.** This is a first pass over the fresh six iPad frames only. Phone frames and previews were deliberately not reviewed. Final full-set JSON scoring remains pending fresh, repaired evidence.

Inspected `ipad-gallery.png`, every `01`–`06` iPad PNG in `AppStoreAssets/ReleaseScreenshots/en-US`, and all six corresponding original captures (`08`, `09`, `11`, `12`, `13`, `14`) in `fastlane/screenshots/en-US`, at original scale. Applied the screen-design-quality-gate rubric, the Utilities category guidance, and the three current private reference examples: Tiny Decisions, Spin The Wheel, and Decide Now. The references establish immediate mechanic/result recognition and one legible benefit per listing slide; their artwork, palettes, and device framing are not templates.

## Required repairs

1. **All six frames: remove the empty colored tab over the screenshot.** It cuts through the captured status-bar time/date. This is presentation-generated overlap, absent from the raw sources, and looks like an unfinished label. Place any retained decoration outside the screenshot's content.
2. **Replace the common top-focused crop strategy for feature slides 03–06.** At gallery scale, the repeated contestant input dominates four different promises. The active mechanic, history, and confirmation sit low and become hard to distinguish. Use coherent crops or fresh scrolled captures centered on each promised feature; do not stretch the capture, invent a control, or crop through the important card/count. This shared composition problem needs one systematic framing repair, not small padding adjustments.

| Slide | Concrete finding | Suggested composition repair |
| --- | --- | --- |
| 01 Celebration | Winner #7 and Ava Thompson agree. Confetti is composited on a light background with no opaque black rectangle. The card and controls are complete. The full-viewport presentation leaves a large confetti region above the winner, reducing the signature reveal at listing size. | Retain the winner-led concept; a tighter crop around the complete winner card and visible character would give the number/name greater prominence. Remove the tab/status collision. |
| 02 Paste | The 16-ready input and Add action support the setup promise. Much of the lower frame is disabled Spin and empty space unrelated to pasting. | Let the contestant editor and Add action dominate. A shorter feature crop with deliberate surrounding composition is better than filling a portrait panel with blank app space. |
| 03 Quick Pick | Quick Pick is selected and Spin is enabled; 16 total is coherent. But the setup editor occupies more space than the promised one-tap draw. The bottom frame cuts through an active-pool row. | Center Draw Setup, Spin, and the complete pool header plus a small number of intact rows; remove the repeated input from this slide's focal area. |
| 04 Spin Wheel | The real vertical numbered picker is shown truthfully. Its numbers are readable at original size, but the mechanic sits low and becomes tiny in the gallery. The pool is cropped through a row. | Use the wheel panel as the dominant object with its selected number/name, spin action, and enough mode context. Preserve the real picker; do not substitute a segmented wheel. |
| 05 No Repeats | Actual result `9. Priya Shah` matches history; raw pool count is 15. The marketing crop puts history at the bottom and clips the active-pool header/count. This weakens the proof of the promised no-repeat behavior. | Feature the No Repeats setting, numbered result/history, and whole remaining-count header together. Change footer `CLEAR HISTORY AT A GLANCE` to `RECENT PICKS AT A GLANCE` to avoid sounding like a delete-history action. |
| 06 Reset | The actual confirmation explicitly says names are kept while inclusion/history reset. It supports the headline, but is small and low relative to the repeated dimmed input. | Give the entire dialog substantially more visual prominence, retaining contextual list rows. Keep both actions and the explanatory sentence fully readable. |

## Evidence that should be retained

The name set is consistent across the setup and active-pool examples. `16 READY` before add, `16 TOTAL` after add, and the actual Priya result/history with `15 TOTAL` remaining form credible state evidence. The winner's number, name, and supporting sentence agree. The bold type, outlines, and color treatment are specific to the current NameSnap UI rather than a copy of the three references. Listing headings are clearly outside canonical app content. No new product art direction is needed to fix these store-framing problems.

The current gallery does not meet the quality floor because of status-bar overlap and weak feature hierarchy/crops. Re-render after the framing repair, then inspect all originals and a listing-scale gallery again. Dynamic behavior, hit targets, and preview pacing/audio remain outside this still-image first pass.

## Second rendered pass — feature-focused crops

Reopened the regenerated gallery and all six original-sized iPad marketing PNGs after the first repair. The first-pass findings above are historical; the following is the current disposition.

- **Resolved:** all empty tabs are gone, so the presentation no longer overlaps the status-bar time/date.
- **Resolved:** slides 03–06 now feature the promised operation. Spin is prominent in 03; the actual numbered picker is prominent in 04; 05 brings result, history, and the whole `15 TOTAL` badge into view; 06 makes its reset confirmation substantially more legible. The gallery now has distinguishable functional silhouettes. Main cards retain their rounded edges and readable values, with no name/count contradiction found.
- **Remaining crop repair:** 03–06 narrow the source horizontally while retaining the full-width pinned bottom toolbar. This cuts off the outer rounded ends of Reset Pool and Clear Pool at the marketing frame's left/right edges. The labels survive, but the controls look amputated. Retain the full source width if including this toolbar, or omit the toolbar with a clean crop boundary above it. Do not stretch the source to compensate.
- **Pending copy render:** 05 still visibly says `CLEAR HISTORY AT A GLANCE`. The source is reportedly changed to `RECENT PICKS AT A GLANCE`; that repair is not marked verified until the new pixels contain it.
- **Minor tradeoffs, not additional blockers:** 02 still gives space to the disabled Spin below the input, but the input is larger and clearer than the first pass. 01 still uses a full-screen celebration with generous surrounding confetti space; the winner number/name remain recognizable. These can be evaluated as part of the eventual full-set score rather than forcing another redesign.

Status remains **REPAIR REQUIRED** for the toolbar crop and final footer render. Phone assets and previews remain unreviewed. No numerical full-set grade issued yet.
