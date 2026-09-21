# NameSnap picker session fix — independent release review

Reviewed September 21, 2026. **PASS for the bounded behavioral regression scope. No actionable regression found.**

I inspected the current `app/namesnap-web-app.tsx` diff, its surrounding state transitions, `tests/picker-session.browser.test.mjs`, and all five supplied PNGs at original resolution. The existing design was treated as unchanged. I did not read the creator's critique, edit implementation files, operate browser tabs/accounts, or rerun browser tests.

## Behavioral assessment

- **Batch submission:** `appendNamesToPool` clears the editor after insertion. It also consumes the draft when Skip duplicates produces an empty batch. The free-limit branch returns before clearing, so an unpurchased queued batch remains editable. Desktop and phone added renders show an empty editor, zero ready to add, disabled Add names, and an active pool of three.
- **Subsequent batch:** `addNames` still parses only the editor. Clearing consumed input prevents earlier additions from being submitted again; duplicate normalization and detection are unchanged. The test asserts the exact Alex/Jordan/Casey pool and absence of the duplicate modal after the second batch.
- **Real duplicates:** The rendered dialog retains visible Cancel, Skip duplicates, and Add all anyway actions. Their source paths preserve the draft on Cancel, consume the accepted draft on Skip, and retain intentional duplicates on Add all. Tests cover duplicates within a batch, against the pool, and an all-duplicate skipped batch.
- **Undo:** The handler finds the last batch by stable IDs, prepends its surviving names to the newer unsubmitted draft, and removes only those IDs from the pool/exclusions. It then clears the undo marker. The test verifies Alex/Jordan return ahead of Casey and that re-adding produces the expected three entries.
- **Fresh session:** Both the pending names and submitted-draft storage keys are cleared along with local picker state. Purchase identity and entitlement state are untouched by this change. The test verifies that a later checkout success does not resurrect discarded names. The supplied fresh renders are captured after adding Alex/Jordan again, so their pool count of two is expected rather than evidence of incomplete reset.
- **Late checkout return:** The submitted editor snapshot is stored separately from queued names. On successful completion, the functional input update clears only an editor still equal to that snapshot, preserving a changed draft. Queue keys are removed after consumption. Tests cover both clearing the unchanged 17-name draft and retaining a newer New participant draft.

## Rendered and test evidence

`desktop-added.png`, `desktop-fresh.png`, `phone-added.png`, and `phone-fresh.png` consistently distinguish the empty draft from the populated pool. No new clipping, control overlap, contradictory count, or incorrect enabled state is visible. `actual-duplicate.png` accurately describes one duplicate and presents all three choices without clipping.

The eight browser tests contain meaningful assertions on both pool and draft, reload/continue behavior, duplicate decisions, queued payment return, and paid access after fresh start. The `test:picker` command builds the static site before testing, preventing the standard command from exercising stale output. The parent reports all eight tests passed; this review independently inspected their assertions and implementation paths, rather than claiming a second test run. Stripe status and checkout are fixture responses, so the result establishes local session behavior, not a real payment.

No repair is required for this diff. This approval does not broaden into an art-direction review or reapproval of unrelated picker features.
