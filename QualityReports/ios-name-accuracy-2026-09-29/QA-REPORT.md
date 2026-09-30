# NameSnap iOS name accuracy QA — September 29, 2026

Candidate: NameSnap 2.0 (32), `com.marcuskim.namesnap`.
Scope: individual contestant input, pool mutation, eligibility, winner identity, history, simulator behavior, and TestFlight verification on Marcus's iPhone. This is not approval for public App Store release.

## Findings and fixes

- Numeric names were corrupted by the list-prefix parser: `2Pac` became `Pac`, `123Alex` became `Alex`, and `007` disappeared. The shared editor/model parser now strips only explicit numbered-list prefixes with a delimiter and following whitespace.
- Removed, excluded, or already-consumed contestant snapshots could be committed as winners. Winner commits now resolve a currently eligible UUID and its current name/number.
- Delayed Quick Pick/wheel callbacks could outlive a pool mutation. A generation token cancels obsolete spins on add, undo, delete, toggle, reset, clear, or visual-mode changes.
- Programmatic draws now commit the captured contestant identity once instead of reparsing display text or re-reading a changed wheel.
- Wheel eligibility follows the same no-repeat rule as Quick Pick. Rounded animation ticks no longer add extra travel beyond their planned target; forced recentering preserves the contestant offset.
- Duplicate prompts compare against eligible contestants and do not appear for an empty eligible pool.
- Multiline paste into an existing text field now preserves text outside its selection.
- Clearing the complete first row dropped keyboard focus and silently ignored subsequent typing. The editor restores focus to the surviving/empty row after the table reload.
- Real-device testing exposed the winner close button overlapping the status area. Build 31 places it inside the safe area, outside the card entrance animation, with decorative layers excluded from hit testing. A light backdrop preserves status-text contrast.

## Automated evidence

- Baseline: 26 XCTest cases; 6 cases failed with 7 assertions, exposing numeric-name corruption, stale/excluded/double winner commits, and clear/delete during a spin.
- Initial corrections: 40 cases passed.
- Final build 31 source: **41 cases passed, 0 failed, 0 skipped** on iPhone 16e / iOS 26.3.1.
- Includes 34 model tests and 7 UIKit input-editor tests.
- Coverage: numbered/comma/newline parsing; numeric and Unicode names; duplicate UUID isolation; row edit/delete; input/pool independence; append/undo/renumbering; eligible-only winners; stale snapshots; repeat/no-repeat behavior; bounded historical snapshots; wheel wrapping and alignment; asynchronous cancellation in both draw modes; 500 individually identified contestants; partial Unicode/multiline paste; first-row keyboard focus.
- Machine-readable result: `test-results-summary.json`.
- Full local XCTest result: `/tmp/namesnap-build31-tests.xcresult`.

## Simulator interaction evidence

Passed through native Simulator controls:

- Entered `2Pac`, `007`, `Alex`, `Alex` using the keyboard and Return. Initial add produced four numbered contestants and retained the input.
- Adding those names again produced the genuine duplicate dialog. Skip added none; Add all added the requested separate entries; Undo removed exactly the latest batch.
- Quick Pick selected #4 Alex; modal and history agreed, and #3 Alex remained eligible.
- Deleted active #3 Alex while the previously picked #4 Alex remained stored but excluded. The surviving original #4 Alex was renumbered to #3; the two numeric names were unchanged.
- Reset restored that surviving Alex and the numeric names, and cleared history. Thus the later wheel screenshot correctly shows #3 Alex: it is the original picked duplicate, not the deleted duplicate.
- Wheel picked #2 `007`; the result and history agreed and the winner left the eligible pool.
- Clearing the pool retained the draft; adding it again did not show a stale duplicate prompt.
- Clearing the input retained the active pool.
- Repeat mode retained all three eligible entries after draws. A subsequent immediate X-button action dismissed the winner before its ten-second timeout.
- Edited only the third fixture row from `Zoë` to `Zoe Updated`; its neighbors were unchanged. Deleting the first input row preserved `007`, the edited row, `李雷`, and both Alex rows with contiguous input numbering.
- Reproduced first-row keyboard-focus loss before its fix. On build 30, deleting all of `Alex` then typing `Jordan` worked without tapping again. Return entered `Casey` on the next row; backspace removed it and returned focus to `Jordan`, where typing `X` produced `JordanX`.
- Debug threshold fixtures: 16 names were admitted; 17 showed upgrade without adding any pool entries; declining preserved the 17-name draft.

Manual clipboard-paste automation timed out without changing the text in the later simulator pass. Manual clipboard paste remains unverified; automated UIKit paste regressions passed. Unicode input rendering was inspected with an explicitly seeded Debug fixture.

## Archive and TestFlight

- Build 29 uploaded successfully, then was superseded by build 30's final keyboard correction.
- Build 30 and final build 31 Release archives/exports and Apple validation succeeded.
- Inspected exported bundle: version 2.0, build 31, iOS minimum 18.0; no `.xctest` bundle and no Debug fixture/entitlement override strings in the executable.
- Build 30 uploaded successfully (delivery `05b4efe2-a95b-4893-8278-2c31821886c1`), completed Apple processing with state `VALID`, and is available to the existing NameSnap Alpha Testers and NameSnap Test July 24, 2026 internal groups.
- Build 31 uploaded successfully (delivery `c37cb46f-6acf-4b14-b9ba-2dcfcd35c6fc`), completed Apple processing with state `VALID`, and was distributed to the same two existing internal groups.
- Final IPA: `artifacts/runs/20260929-200221-testflight/NameSnap.ipa`.
- Real iPhone TestFlight installation of final version 2.0 (31) was verified with its Build 31 label and Open button.
- No App Store review submission or public release was performed during these TestFlight checks. The later authorized review submission is recorded below.

## Actual iPhone interaction evidence

Build 30 was installed from TestFlight and tested through iPhone Mirroring using disposable names:

- Entered `2Pac`, `007`, `Alex`, `Alex`; Add retained the draft and created four numbered contestants.
- Quick Pick selected #1 `2Pac`. Subsequent wheel draws selected #4 Alex, #2 `007`, and #3 Alex. The exhausted history contained each original number exactly once; the wheel showed no available contestants.
- Re-adding after exhaustion showed no duplicate confirmation. Undo removed exactly the four newly added entries and retained the draft.
- Reset restored the four original contestants and cleared history. Deleting #3 Alex left #1 `2Pac`, #2 `007`, and the original #4 Alex renumbered to #3.
- Excluding #2 `007` left only `2Pac` and the surviving Alex eligible; their names were unchanged.
- Clearing the pool retained all four draft names. Re-adding to the empty pool succeeded without a duplicate warning. Clearing the draft afterward left four contestants in the pool.
- The build 30 winner X overlapped the phone status area; Keep Going worked. This observation drove the build 31 safe-area fix, which was then hit-tested on the simulator using a non-expiring winner fixture.

Final build 31 follow-up on the same real iPhone:

- TestFlight displayed version 2.0, build 31, Open.
- Cleared the first input row and typed `2Pac` without tapping the field again; Return then entered `007` in row two. A rapid batch of remote keystrokes initially raced the editor reload; individually observed interactions and the UIKit regression test passed.
- Added both names, drew #2 `007`, inspected the winner and tapped the X at its new position below the Dynamic Island. The modal dismissed immediately, before the ten-second timeout.
- Evidence: `iphone-testflight-build31-installed.jpg`, `iphone-build31-live-winner.jpg`, `iphone-build31-immediate-close.jpg`.

Final build 32 follow-up on the same real iPhone:

- TestFlight displayed version 2.0, Build 32, Open; installation is confirmed.
- Entered `2pac` and `007`, added both, and drew contestant #1. The winner displayed `2PAC` in the app's uppercase display style, matching #1.
- Confetti rendered on the light backdrop without the opaque black rectangle found during iPad asset capture.
- Tapped the stationary X below the Dynamic Island immediately after the reveal. The modal closed before the ten-second timeout; dismissal is operator-observed and supported by before/after captures.
- Evidence: `build32-installed.jpg`, `build32-phone-winner.jpg`, `build32-phone-dismissed.jpg`.
- Build 32 changes only confetti screen blending after build 31's 41-test pass. A focused numeric-name regression passed again on build 32; the 41-case result remains explicitly attributed to build 31.
- Build 32 archive/export and Apple validation succeeded. Delivery `bb0cff33-4d50-42c2-8373-236f4ce18ce2` processed `VALID` and was distributed to the two existing internal groups.
- Latest IPA: `artifacts/runs/20260929-203712-testflight/NameSnap.ipa`.
- Current iPad winner rendering was inspected during the asset refresh. This is bounded visual coverage, not a complete iPad interaction/accessibility pass.

## Screenshot interpretation

- `baseline-numeric-name-corruption.png`: before-fix evidence.
- `simulator-fixed-numeric-unicode-input.png`: corrected Debug input fixture.
- `simulator-winner-4-alex.png`: captured after the transient winner modal had expired; it is **not** winner-modal evidence.
- `simulator-wheel-after-close.png`: live #2 `007` result/history with remaining pool.
- `simulator-repeat-history.png`: result view; repeated history rows are outside this crop.
- `simulator-build30-keyboard-replacement.png`: post-fix keyboard edit state.
- `build30-debug-winner-fixture.png`: pre-repair winner fixture, showing the status-area collision.
- `build31-debug-winner-safe-area.png`: repaired non-expiring winner fixture; the X was successfully tapped in the simulator.
- `iphone-build30-exhausted-history.jpg`: the four original numbers each appear once after actual device draws.
- `iphone-build30-delete-one-duplicate.jpg` and `iphone-build30-exclude-single-name.jpg`: individual pool mutations on the phone.
- Independent critiques are recorded alongside this report. They do not constitute full visual or public-release approval. The main scrolling screen still has a pre-existing status-area overlap; build 31 only repairs the winner overlay.

## Remaining boundaries

Purchase/restore transactions, older iOS versions, iPad layout, VoiceOver, and statistical randomness distribution have not been exhaustively validated by this pass. Public release remains a separate decision after device QA and any remaining release checks.

## App Store review submission — September 29, 10:38 PM PDT

Marcus explicitly authorized submitting mobile for review. Version 2.0 (32) was submitted through the visible App Store Connect review flow after all 12 current screenshots and both current previews completed processing and matched local checksums. The updated icon was verified in the selected build. Apple shows Waiting for Review for submission `0681ac05-10a6-451c-9990-403c899cfa5d`. Manual release remains selected; no public release occurred. Asset and submission evidence is in `../app-store-assets-2026-09-29`.
