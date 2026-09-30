# Independent final preview critique — 2026-09-29

**PASS: 93.7/100 for the final two 21-second previews and their 15-second posters.** No required rendered repair remains. This is a local frame/timeline design review; App Store upload/processing and app-wide behavior are separate.

The earlier montage problem is resolved. Consecutive extracted frames show the real wheel changing under the disabled “SPINNING” action and then revealing an identifiable winner. iPhone resolves to **#8 Ethan Nguyen**; iPad resolves to **#16 Owen Lewis**. Each result persists into its own recent-winner history with **15 TOTAL** before reset confirmation. The initial populated-input shot and final reset segment are editorial cuts, so this is not claimed to be one uncut end-to-end operation.

The last phone crop repair was reopened at 19 and 20.5 seconds. It removes the prior-card fragment and status-icon overlap while retaining the complete reset explanation, Cancel/Reset Pool actions, Ethan history, 15 TOTAL badge, fixed toolbar, and home indicator. The iPad has no comparable edge defect. Both current 15-second posters show their actual winners with whole close/continuation controls. The iPad confetti has no opaque black backing.

Evidence: both final files were independently decoded at two frames per second; overview and consecutive draw-phase galleries were inspected, along with original-resolution spinning, winner, history/reset, repaired ending, and poster frames. Complete-file decoding returned exit 0 and blackdetect found no events at its stated threshold. Each export is 21 seconds / 630 frames, H.264 High / yuv420p at 30 fps, with stereo AAC at 48 kHz. Decoded volume is -91 dB, consistent with the intentionally silent soundtrack. Dimensions are 886×1920 and 1200×1600.

Minor tradeoffs remain: the winner hold is long; the iPad's native layout has generous whitespace and smaller thumbnail details; silent audio does not demonstrate the app's music. The fixed toolbar stays bright behind the dimmed reset content, as in the existing app. These do not hide the demonstrated result or controls.

The JSON contains all twenty scored categories, all ten diagnostics, final hashes, and scope limits. No claim is made about real-time human playback, randomness distribution, VoiceOver, reduced motion, modal hit testing, or execution of the final reset. Legacy 5-second poster files are excluded; only the current 15-second posters were reviewed.

Final movie SHA-256:

- iPhone: `776d5caf4500bc8d5e14dbeb48cdd333248fd412fdd1e473cf9aad8336303289`
- iPad: `536b1d962bdb5dd85692cade801051423c3d7b2c9262f8cf5143adcb8cc13666`

Detailed evidence lives in `final-preview-independent-frames/`; authoritative final encode results are in its `reviewed-video-specifications.json`.
