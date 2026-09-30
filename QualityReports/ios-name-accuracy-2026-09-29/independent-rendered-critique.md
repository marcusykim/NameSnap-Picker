# Independent rendered review — iOS name accuracy

Date: 2026-09-29. Scope: bounded maintenance review of the existing input, numbered pool, result, and winner UI. Reviewed the screen-design-quality-gate skill and critical rubric. No UI interaction or app-code modification was performed.

**Updated verdict: no new release-blocking name/number inconsistency is visible. The build 31 winner render resolves the previously visible status-area collision at the inspected simulator viewport. Real-device build 30 captures now establish the complete four-ID pool and exhausted history. Remaining coverage limits are stated below; this is not full design approval.**

## Direct pixel evidence

Inspected the original-resolution files listed below, including the pre-fix baseline. The task is a host entering names and identifying the selected numbered contestant accurately; names, pool numbers, results, and history are the relevant product objects.

| Artifact | Observed evidence and limit |
| --- | --- |
| `baseline-numeric-name-corruption.png` | Pre-fix evidence only: the visible first row is `1. Pac`; the second is `2. Alex`. Do not use this as current-state evidence. |
| `simulator-fixed-numeric-unicode-input.png` | `1. 2Pac`, `2. 007`, `3. Zoë`, and `4. 李雷` render intact and legibly. The badge says `6 READY`, but only four rows are visible; the two remaining Alex entries are not independently confirmed by this capture. |
| `simulator-wheel-after-close.png` | Result `2. 007` and the visible Recent Winners entry `2. 007` agree. The wheel displays eligible `1. 2Pac` and `3. Alex`, retaining nonconsecutive pool numbers. `2 TOTAL` agrees with those two wheel identities, though the second active-pool row is obscured at this scroll position. The selected wheel row is a different, still-eligible contestant from the last result; this alone is not evidence of an incorrect draw. |
| `build30-debug-winner-fixture.png` | Static Debug fixture only. Badge `7`, `DR. LEE`, and “Winner #7” agree. Close, Keep Going, and Reset Picks are visible and legible; the winner text and action labels are not truncated. This proves the fixture's presentation, not winner selection, dismissal, or state transitions. |
| `simulator-build30-keyboard-replacement.png` | Shows `1. JordanX`, a caret, one ready entry, and the next empty row. It confirms the displayed edited state, not the reported delete-and-continue-typing sequence. |
| `simulator-winner-4-alex.png` | Shows a scrolled main screen after the modal timed out. The result is mostly under the pinned bottom bar. Excluded as winner-modal evidence. |
| `simulator-repeat-history.png` | Shows No Repeats off and result `1. 2PAC`; no history rows are visible. Excluded as repeated-history evidence. |

## Initial visible limitations (before build 31 follow-up)

- **Safe areas:** scrolled content reaches behind the status bar; in the wheel image, the time overlaps “DRAW SETUP.” The build 30 winner fixture's close-button circle also reaches into the status-icon band, although its X remains clear; the follow-up below resolves that winner-specific finding. The provided pre-fix capture is at a different scroll offset, so it does not establish whether these concerns predate the accuracy patch. No evidence attributes them to the accuracy changes.
- **Captured viewport:** the pinned bottom bar hides part of the result/pool in several captures. That limits verification; it does not prove the content cannot be scrolled into view.
- **Hierarchy and accessibility:** numbers, names, buttons, selected modes, and toggles are visually distinguishable. The existing oversized Spin control and celebration art consume substantial vertical space. VoiceOver labels, Dynamic Type, keyboard avoidance, hit testing, motion, and timing were not evaluated from these static images.
- **Category and originality:** the contestant list → draw control → result/history sequence is coherent picker UI. The bold double outlines, color, and celebration remain internally consistent; no store-listing frame or promotional screenshot overlay appears inside the app. No new art direction was selected or assessed against category references, and no broader originality certification is issued.

## Evidence boundary

At the initial review, uncovered visual checks were the actual #4 Alex winner modal, both repeated-history entries with their original numbers, the complete six-name fixture, and complete active-pool rows. The follow-up below supersedes the pool/history coverage limits where supported. No unseen interaction is marked passed. `test-results-summary.json` reports 41 passing tests and zero failures; that separate test result does not fill screenshot gaps.

Accept the observed numeric/Unicode fidelity and internally consistent fixture as supporting evidence for this maintenance change. Preserve the above gaps and safe-area findings in the release record. Full twenty-category scoring, broad design certification, and interactive accessibility approval are outside this bounded review.

## Follow-up — build 31 winner safe area and real-device evidence

Independently reopened `build30-debug-winner-fixture.png` and inspected the fresh `build31-debug-winner-safe-area.png` at original resolution. Also inspected the five real-device JPEG captures below. No UI was operated.

**Winner safe-area repair: accepted within the inspected 1170 × 2532 simulator render.** Build 30's close circle overlapped the status-icon band. In build 31, the whole close circle and X sit below the status bar, visibly separated from the Wi-Fi/battery icons. The status bar has a light background; its black text and icons remain clear. The card is inset from the screen top and bottom. Number 7, DR. LEE, Winner #7, Keep Going, and Reset Picks remain legible and internally consistent, without new clipping or control overlap. The visible change fixes the specific collision previously recorded.

A still image cannot establish that the close target remains stationary throughout animation or that dismissal works. The implementer separately reports an actual CUA click dismissing the non-expiring Debug fixture; this removes the earlier timeout confound but is reported interaction evidence, not an interaction independently executed by this critic.

| New real-device artifact (build 30) | Direct observation |
| --- | --- |
| `iphone-build30-four-contestants.jpg` | Complete active pool: `1. 2Pac`, `2. 007`, `3. Alex`, `4. Alex`, with `4 TOTAL`. The duplicate display name has two distinct visible pool IDs. |
| `iphone-build30-quick-pick-winner.jpg` | Winner badge 1, name 2PAC, and Winner #1 agree with the initial pool. |
| `iphone-build30-wheel-winner.jpg` | Wheel displays `2. 007` and `3. Alex`; the lower result is partially obscured. This is not accepted as a complete winner-modal capture despite the filename. |
| `iphone-build30-wheel-second-result.jpg` | Winner badge 2, name 007, and Winner #2 agree; leading zeros remain intact. |
| `iphone-build30-exhausted-history.jpg` | No Repeats is on; wheel says “No available contestants.” Result is `3. ALEX`. History reads `3. Alex`, `2. 007`, `4. Alex`, `1. 2Pac`: each original ID appears once, and the two Alex contestants remain distinct. This closes the complete four-ID history evidence gap. |

**Remaining limits:** these JPEGs are small, compressed 318 × 701 captures, sufficient to read the key values but not to certify fine text rendering or hit targets. They show build 30, so the build 31 safe-area repair is not yet visually verified on the Dynamic Island device. Actual #4 Alex modal presentation, repeated draws with No Repeats off, the final two rows of the six-name Unicode fixture, other sizes/orientations, and interactive accessibility remain unverified. Existing main-screen content beneath the status bar remains visible in build 30 images; this follow-up accepts only the winner safe-area repair and makes no claim that main-screen scrolling was repaired.

No remaining release blocker was found within this narrowly inspected winner safe-area/close-control presentation. The refreshed test summary still records 41 passes and zero failures; screenshot conclusions remain independent of that count.
