# NameSnap TODOs

## Release checklist additions
- Create final App Store preview image assets / listing carousel images.
- Make sure the screenshot set matches final monetization, privacy/support wording, and final positioning.
- Export the final assets in valid App Store sizes and keep editable/source versions organized.

## 1. Backspace / keyboard behavior in contestant rows
- **Bug A:** When the cursor is at the beginning of an empty contestant row, pressing backspace/delete should move focus to the row above and place the cursor at the end of that row.
- **Current wrong behavior:** The cursor stays on the empty row instead of jumping upward.
- **Bug B:** When a row contains a name and the user deletes all letters one by one with backspace, deleting the final remaining character causes the software keyboard to dismiss itself.
- **Expected behavior:** The keyboard should remain open after deleting the final character so the user can continue editing/navigating naturally.
- **Notes:** A delegate-based attempt did not fix Bug A, which suggests the empty-field backspace path is bypassing `shouldChangeCharactersIn` and needs a lower-level event hook. Bug B suggests the field/editor lifecycle is also doing something undesirable when a row transitions from non-empty to empty.
