# NameSnap design-token and asset inventory

This inventory is derived from the shipped iPhone/iPad implementation in
`../NameSnap/ContentView.swift` and `../NameSnap/Assets.xcassets`. The web app
must consume these values before introducing a local value. Values marked
“web adaptation” preserve the mobile grammar while accounting for pointer,
large-screen, and broadcast use.

## Color

### Canonical product palette

| Token | Value | Mobile source | Use |
| --- | --- | --- | --- |
| `--ns-bg` | `#E0F4AB` | `NSTheme.bg` | Page field |
| `--ns-sky` | `#6BA3CC` | `NSTheme.skyBlue` | Wordmark, borders, informational emphasis |
| `--ns-tan` | `#C7AB8A` | `NSTheme.tan` | Warm neutral accents and segmented-control field |
| `--ns-card` | `#F2F4FA` | `NSTheme.card` | Primary cards and modal material |
| `--ns-yellow` | `#F7DC60` | `NSTheme.yellow` | Count, selection, winner emphasis |
| `--ns-indigo` | `#5856D6` | iOS `.indigo` | Primary action and selected state |

### iOS semantic accents

| Token | Value | Use |
| --- | --- | --- |
| `--ns-red` | `#FF3B30` | Destructive controls and trash icons |
| `--ns-orange` | `#FF9500` | Undo or cautionary secondary action |
| `--ns-pink` | `#FF2D55` | Wheel segment/accent |
| `--ns-cyan` | `#32ADE6` | Wheel segment/accent |
| `--ns-green` | `#34C759` | Success |
| `--ns-purple` | `#AF52DE` | Focus/accent |

### Text and material neutrals

| Token | Value | Source/use |
| --- | --- | --- |
| `--ns-ink` | `#15151B` | Web equivalent of iOS label/black |
| `--ns-input-text` | `#141414` | Mobile input `white: 0.08` |
| `--ns-number-text` | `#333333` | Mobile input-number `white: 0.20` |
| `--ns-placeholder` | `#595959` | Mobile input placeholder `white: 0.35` |
| `--ns-text-secondary` | `#455D73` | Web-adapted secondary blue-gray |
| `--ns-text-tertiary` | `#60758B` | Web-adapted tertiary blue-gray |
| `--ns-white` | `#FFFFFF` | Input and selected surfaces |
| `--ns-disabled-bg` | `#E8EDF2` | Disabled surface |
| `--ns-disabled-text` | `#8793A1` | Disabled label |
| `--ns-disabled-line` | `#BDC8D1` | Disabled edge/depth |

Alpha must be derived from a named color: card border is sky at 12%, input
border is sky at 80%, modal stroke is white at 65%, and disabled destructive
background is red at 12%.

## Typography

- Display family: bundled `RubikMonoOne-Regular.ttf`, CSS family
  `"Rubik Mono One"`. Use for the NameSnap wordmark, primary action labels,
  picker headings, and winner/upgrade headlines only.
- Operational family: `-apple-system, BlinkMacSystemFont, "SF Pro Text",
  "Segoe UI", sans-serif`.
- Mobile display sizes: 38 app title, 32 classic Spin, 24 modal title, 22
  upgrade title, 16 wheel section, 15 Spin Wheel, 14 Add Names, 13 secondary
  actions, 12 tertiary actions.
- Mobile operational styles: iOS body 17, headline 17 semibold, subheadline
  15, footnote 13, caption 12. Web may scale display headings responsively but
  must keep their role and family.
- Avoid negative display tracking that distorts Rubik Mono One. Operational
  copy uses normal tracking; micro-labels may use 0.12–0.17em uppercase.

## Spacing and geometry

- Core spacing steps: 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24.
- Screen stack gap: 16. Card content padding: 14. Input shell inset: 8.
- Input editor row height: 32.
- Input number gutter: 28 wide, right aligned; 2 leading and 6 after number.
- Input trash: 16-point bold optical glyph in a 22-by-22 mobile frame. Web
  adaptation uses a 36-by-36 pointer target and 44-by-44 touch target while
  retaining a 16-pixel glyph.
- Pool row content gap: 10. Pool trash: 16-point outline optical glyph in a
  28-by-28 mobile frame; web uses the same accessible target adaptation.
- Standard web panel width: 370 desktop and 330 compact desktop. Responsive
  layout collapses at 820; narrow-phone refinements begin at 560.

## Radius

- `--ns-radius-input`: 12 (mobile input shell and wheel empty state).
- `--ns-radius-result`: 14 (selected winner strip).
- `--ns-radius-card`: 16 (primary card surface).
- `--ns-radius-modal`: 18 (action modal material and web stage adaptation).
- `--ns-radius-pill`: 999 (capsules, primary actions, toggles).

## Borders, depth, and material

- Card: `1px` sky at 12%; no mobile card shadow.
- Input: `2px` sky at 80% on white.
- Stage (web adaptation): `2px` sky at 80%, card fill, 18 radius.
- Modal: ultra-thin/translucent card material, `2px` white at 65%, 18 radius,
  12-point soft shadow/blur.
- Yellow spin glow: yellow at 50%, blur radius 10, vertical offset 4.
- Web card depth token: `0 12px 24px rgba(47,62,83,.14)`; use only where a
  large desktop surface needs separation, never on every nested object.
- Web indigo action depth: `0 8px 16px rgba(88,86,214,.20–.22)`.

## Assets and icon contract

- App icon: exact `AppIcon-1024.png`, published as `/namesnap-icon.png`.
- Font: exact bundled Rubik Mono One file at `/brand/RubikMonoOne-Regular.ttf`.
- Mobile image-set inventory: `Icon_settings` (1x/2x/3x), `dragon_pointer`
  (1x/2x/3x), `icon_lock` (1x/2x/3x), and the single-source `broom_emoji`,
  `party_popper_emoji`, `recycle_emoji`, `repeat_emoji`, `sound_emoji`,
  `sparkle_emoji`, `success_emoji`, `undo_emoji`, and `warning_emoji` sets.
- Emoji imagery: use those exact app assets, not platform emoji, whenever the
  app has a named image. Current web copies: party popper, repeat, sound,
  sparkle. Add another only when the corresponding UI state is added.
- Input-row delete: mobile SF Symbol `trash.fill`, 16-point bold, tinted iOS
  system red. Web asset `/brand/trash-fill.svg` is its currentColor mask
  equivalent. It appears only for a populated staged-input row.
- Pool delete: mobile SF Symbol `trash`, tinted iOS system red. Web asset
  `/brand/trash.svg` is its currentColor outline-mask equivalent. Do not use
  `×`, a text glyph, an emoji, or the filled input symbol here.
- All icon-only buttons require a visible focus state and an accessible label
  naming the contestant affected.

## Input and numbering behavior

1. The editor always shows numbered rows and one numbered trailing entry row.
2. Numeric prefixes pasted by a user are removed before NameSnap applies its
   own contiguous numbering.
3. Pasting comma- or newline-separated values expands them into rows.
4. Every populated staged row gets its own filled trash control; the trailing
   entry row does not.
5. Permanent removal renumbers staged input and the pool contiguously.
6. Adding a batch to the pool appends the next pool number.
7. No-repeat exclusion does not renumber the pool; winner and history retain
   the number at draw time.

## Motion and accessibility

- Control feedback: 160–180ms. Wheel reveal: 3.8s.
- Honor `prefers-reduced-motion` by disabling nonessential transitions.
- Primary actions and touch delete controls are at least 44 points on touch
  layouts. Focus uses purple; destructive controls always combine red with a
  trash shape and an accessible name, never color alone.
