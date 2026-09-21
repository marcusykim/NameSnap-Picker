# Immediate winner-modal dismissal

September 21, 2026. Site: https://getnamesnap.web.app.

## Reproduction and repair

The winner card's 700ms entrance animation scaled and rotated the whole modal,
including its close button. Measurements across animation frames reproduced
roughly 20–40px of close-target movement on desktop, phone, and landscape. The
right-side guitarist image also intercepted pointer hit testing at the desktop
close button at the 4900ms animation pose, despite being decorative.

The modal now appears in its final position immediately. Decorative hero images
ignore pointer input, matching the other celebration decorations. Confetti,
character animation, audio, and dismissal handlers remain unchanged.

## Validation

Three new browser regressions failed before the repair and passed after it.
They use the real rendered modal at 1440 x 1000, 390 x 844, and 844 x 390. In
isolated fixtures, the guitarist celebration is selected deterministically and
CSS animation times are sampled at 80, 200, 650, 1200, 2100, and 4900ms. Every
sample now resolves pointer hit testing to the close button at the same position.
Raw mouse input (desktop/landscape) and touch input (phone) at the 200ms pose close
the modal without locator auto-waiting for animation completion. The entered name
and the completed pick remain intact.

All 17 picker browser regressions passed. The three new cases were rerun after
adding late-animation screenshots and passed again. All 10 build/render tests,
ESLint, and the production static build passed. No account state was changed and
no payment was submitted by the fixture tests.

The six screenshots show the early (200ms) and late (4900ms) celebration poses in
all three viewports. Review is limited to the close interaction and visual
regressions; it does not certify a redesigned interface. The existing close glyph
is small within its larger hit target; styling was not changed by this patch.

## Release

Visible Firebase identity was verified in the existing canonical NameSnap project
tab: Marcus Kim, marcuskim1989@gmail.com, expected NameSnap project. The platform
manifest was updated to signed-in. No additional project tabs were created.

Static assets: `index-C9RBPEd1.js` and `index-zzUqVPZJ.css`.
Firebase Hosting deployment completed for site `getnamesnap` in project
`namesnap-picker-6759588637`. Production HTML and both assets returned HTTP 200.
The deployed JavaScript and CSS match the tested local build byte-for-byte; full
hashes are recorded in `deployed-assets.json`. Existing open tabs need a refresh
to load the new stylesheet. Production picker data was not modified for testing.
