# NameSnap App Store asset refresh — September 29, 2026

Status: uploaded, verified, and submitted with version 2.0 (32). Apple status: Waiting for Review. Manual release is selected.

## Product and scope

The first user is a teacher, streamer, host, or group organizer who needs to add a list, make an identifiable random pick, and run another round without losing control of individual entries. The intended response is confidence in the numbered result with a playful reveal. This is an App Store listing refresh using the implemented interface, not a new product UI design.

Candidate 2.0 (32) includes the tested identity/input fixes, the winner safe-area repair, and screen blending for the confetti GIF to remove its opaque black background on the light backdrop.

## Reference research and direction

The Utilities guide in the maintained category library was consulted. Current Apple lookup metadata and screenshots were retrieved on September 29 for three products in the random-selection task family:

- [Tiny Decisions](https://apps.apple.com/us/app/tiny-decisions-spin-wheel/id1338769645), version 26.10: one concise promise and a large, legible draw object.
- [Spin The Wheel](https://apps.apple.com/us/app/spin-the-wheel-random-picker/id1467343690), version 2.20.2: recognizable mechanic and result; the busy paper background and aged device framing are anti-patterns, not templates.
- [Decide Now!](https://apps.apple.com/us/app/decide-now-spin-the-wheel/id383718755), version 2.4: short action-led copy and direct transition to a wheel.

Reference assets remain private research in `/tmp/namesnap-current-store-references`; none are delivered or reused.

Three directions were considered:

1. Utility-first: large draw control first, then input, result, and history. Clear but downplays NameSnap's celebration artwork.
2. List-first: contestant roster dominates, with manipulation and no-repeat history following. Useful for classrooms but understates live-host appeal.
3. Celebration-first: the real winner reveal leads, then setup, both draw modes, history, and reset. Selected to preserve the established NameSnap listing language and show its signature result while proving the operational controls afterward.

The frames retain NameSnap's own typography, outlined surfaces, violet shadows, and warm action colors. Captured app UI is distinct from listing headlines and presentation framing. NameSnap's vertical numbered picker is shown truthfully; no segmented wheel is invented.

## Capture and validation

- All new renders use the current app source and synthetic names.
- Setup, draw-mode, winner, and reset fixtures seed normal app views; they do not prove a real random draw.
- iPad history uses an actual draw from build 31, whose main-screen UI is unchanged in build 32. iPhone history is a deterministic fixture that calls the production winner-commit method for #7 Ava Thompson, #9 Priya Shah, and #12 Leo Garcia, leaving 13 eligible entries. These are display fixtures, not evidence of random draws.
- iPhone captures come from iPhone 16e at 1170×2532, framed at Apple's 1320×2868 upload size; the existing `6_9` filenames describe the upload slot. iPad captures are native 13-inch.
- A temporary capture-only patch positions the normal ScrollView at the draw/history section without hiding or inventing controls. It is preserved in `scripts/app-store-capture-viewport.patch`, and was removed from the shipping source after capture. Top cropping in marketing frames avoids partial preceding cards/status-area overlap. This does not fix the separately documented main-screen scrolling safe-area issue.
- Screenshot sizes: iPhone 1320×2868 and iPad 2064×2752, opaque RGB PNG.
- Preview targets: iPhone 886×1920 and iPad 1200×1600; 21 seconds, H.264, 30 fps, stereo AAC. A three-second input scene leads into fourteen seconds of continuous actual spin-to-winner footage and four seconds of the corresponding reset confirmation. Phone winner #8 Ethan Nguyen and iPad winner #16 Owen Lewis match their histories; both reset scenes retain 15 eligible contestants. Phone draw/reset detail footage crops the top 120 source pixels and preserves aspect with pale padding. Footage is current simulator rendering, with no fabricated controls. Audio is intentionally silent.
- [Apple screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/) and [preview specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/app-preview-specifications/) were checked during this refresh.
- Independent design and release critiques, hashes, and upload evidence are stored in `QualityReports/app-store-assets-2026-09-29`. All 12 screenshots and both previews processed COMPLETE, and Apple's source checksums match the local files. Both preview poster time codes are `00:00:15:00`.

Marcus authorized submission of mobile version 2.0 (32) for App Store review on September 29 after the asset refresh. Manual release was selected and saved in the visible App Store Connect draft. Public release remains a separate action.

The visible submission completed September 29, 2026 at 10:38 PM PDT. Submission ID: `0681ac05-10a6-451c-9990-403c899cfa5d`. The submitted item is version 2.0 (32), and the page shows Waiting for Review. Proof: `asc-submitted-build32.png`; independent API evidence: `asc-review-submission.json`; asset verification: `asc-upload-verification.json`.
