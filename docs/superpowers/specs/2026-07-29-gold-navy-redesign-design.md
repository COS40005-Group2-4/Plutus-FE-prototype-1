# Plutus Gold/Navy Redesign — Design Spec

**Date:** 2026-07-29
**Status:** Approved (brainstorming complete)
**Scope decision:** `lib/` + `packages/dashboard/` + `web/` shell
**Approach decision:** Approach B — new `ThemeExtension` token layer with full call-site migration, staged behind revalued deprecated shims.

## 1. Goal

End-to-end visual/UX overhaul of Plutus: calm, minimalist, premium gold/navy design
language derived from the logo (gold Doric column, navy laurel + cornucopia, Trajan-style
wordmark). Functionality, routes, provider wiring, and service calls are untouched —
re-skin plus UX polish, not a rewrite. Both light and dark themes are first-class.

Decisions locked during brainstorming:

- **Accent policy:** collapse the ~14 per-widget dashboard accents into the gold/navy
  system. Gold is scarce (CTAs, hero figures, active states, fine accents); navy is
  structural (text, headers, chrome). Charts get one restrained categorical palette.
- **Surfaces:** retire glassmorphism and tinted glow shadows. Calm opaque cards,
  hairline borders, soft neutral layered shadows.
- **Typography:** bundle Inter (UI) + Cormorant Garamond 600 (classical accent, two
  uses only).
- **Delivery:** 4 phased PRs to main, conventional commits, each PR independently green.

## 2. Token architecture

### 2.1 `PlutusTokens` (new: `lib/theme/plutus_tokens.dart`)

`class PlutusTokens extends ThemeExtension<PlutusTokens>` registered on both light and
dark `ThemeData`. Holds everything brightness-dependent:

- Semantic colors: `bg`, `surface`, `surfaceSubtle`, `border`, `borderStrong`, `text`,
  `textSecondary`, `textMuted`, `brandNavy`, `gold`, `goldHover`, `goldWeak`,
  `goldText`, `onGold`.
- Status quartets (`success`, `warning`, `info`, `error`), each a value object with
  `text` / `surface` / `border` / `dot`. Status is always expressed as the full quartet.
- Chart categorical palette (`List<Color>`, 6 entries) + gold sequential ramp for
  heatmaps.
- Elevation shadow sets: `shadowLow`, `shadowMedium`, `shadowHigh`.
- Hero-card decoration tokens (hero surface color, gold hairline border color).

`lerp()` implemented for every field so the existing `AnimatedThemeScope` light↔dark
animation interpolates smoothly.

**Access pattern:** `context.tokens` extension getter
(`Theme.of(context).extension<PlutusTokens>()!`) in `lib/theme/plutus_tokens.dart`.
No widget writes `Brightness` conditionals.

### 2.2 What stays static/const

`AppSpacing`, `AppRadius`, `AppMotion`, and type-size roles stay compile-time constants
(putting them in the extension would break `const` constructors everywhere):

- **`AppSpacing`** gains the dual scale: component scale `4, 8, 12, 16, 20, 24` for
  padding/gaps inside components; layout scale `24, 32, 48, 64` for spacing between
  sections/cards. Existing names kept; new named constants added.
- **`AppRadius`** revalued: `input 10`, `button 12`, `card 16`, `sheet 20` (dialogs and
  bottom sheets), `pill 999` (chips/badges only). Tables render sharp inside rounded
  card containers.
- **`AppMotion`** kept: fast 150ms / medium 250ms / slow 400ms, easeOutCubic emphasis.

### 2.3 Migration safety net

- **PR1** revalues the legacy `AppColors` / `AppElevation` / `AppGradients` statics to
  the new palette and marks them `@Deprecated`. Unmigrated widgets instantly render in
  gold/navy.
- **PR2–3** migrate all call-sites to `context.tokens`.
- **PR4** deletes the shims. `flutter analyze` / `flutter test` stay green at every
  phase boundary.
- `GlassContainer` / `GlassBackground` are replaced by `AppCard` / `AppCanvas`;
  call-sites migrate during each screen's pass; the glass widgets are deleted in PR4.

## 3. Color system

### 3.1 Reference ramps (internal only — components never touch these)

- **Navy:** 50 `#F4F6FB` · 100 `#E9EDF6` · 200 `#D6DDED` · 300 `#B3BFDB` · 400
  `#8093BC` · 500 `#52659A` · 600 `#33457D` · 700 `#24346A` (logo navy) · 800
  `#1A2650` · 900 `#131C3D` · 950 `#0C122A`
- **Gold:** 50 `#FDF9EC` · 100 `#FAF0CE` · 200 `#F4E09A` · 300 `#ECCB5F` · 400
  `#E0B32F` · 500 `#C9970F` (logo gold core) · 600 `#A67A0B` · 700 `#85610D` · 800
  `#664A0E` · 900 `#4A350B`

### 3.2 Light semantic mapping

| Token | Value | Role |
|---|---|---|
| `bg` | `#F7F8FA` | canvas |
| `surface` / `surfaceSubtle` | `#FFFFFF` / `#F1F3F6` | cards / insets, table headers |
| `border` / `borderStrong` | `#E5E8EE` / `#CDD3DE` | hairlines / inputs |
| `text` | navy-900 | primary text is navy |
| `textSecondary` / `textMuted` | `#4A5573` / `#8A93AB` | navy-tinted greys |
| `brandNavy` | navy-700 | headers, nav chrome |
| `gold` / `goldHover` | gold-500 / gold-600 | CTA fills, active states |
| `goldText` | gold-700 | the only gold used as text on light (AA ≈ 4.9:1) |
| `goldWeak` | gold-50 | selected washes, chip fills |
| `onGold` | navy-950 | text on gold fills (≈ 6:1) |

### 3.3 Dark semantic mapping

`bg #0C1120` · `surface #131A2E` · `surfaceSubtle #1A2340` · `border #232D4A` ·
`borderStrong #33405F` · `text #EDF0F7` · `textSecondary #AAB4CE` ·
`textMuted #6E7A99` · `brandNavy → navy-300` · `gold → gold-400` ·
`goldHover → gold-300` · `goldText → gold-300` · `goldWeak → gold-400 @ 12% alpha` ·
`onGold → navy-950`.

### 3.4 Status quartets (text / surface / border / dot)

Light:

- success `#067647 / #ECFDF3 / #A6F4C5 / #079455`
- warning `#B54708 / #FFF8EB / #FEDF89 / #DC6803`
- info `#33457D / #EFF3FB / #C9D5EF / #52659A`
- error `#B42318 / #FEF3F2 / #FECDCA / #D92D20`

Dark (same hues, brightened text/dot, deep surfaces):

- success `#7BE0AC / #11291D / #1D4A31 / #3CCF8E`
- warning `#F0A94B / #2B1F0E / #5C4413 / #E8912D`
- info `#A9BCE8 / #16213D / #2A3A63 / #7288B5`
- error `#F49A92 / #2C1512 / #5C221C / #E5544B`

All pairs locked by the contrast test; if a pair fails AA the value is nudged, not the
rule.

**Financial semantics:** gains/losses keep the green/red convention via
success/error tokens. Gold is reserved for hero figures (net worth, portfolio total),
never for up/down signals.

### 3.5 Chart palette

- Light categorical: `[navy-700, gold-500, navy-400, #35726E, #6E4E7E, #8A93AB]`;
  dark equivalents brightened.
- Heatmap sequential: gold-50 → gold-700 (light); gold-400 alpha ramp (dark).

### 3.6 Accessibility rule

Raw `gold` is never text on light — only `goldText` / `onGold` pairings exist as
tokens. Every text/bg token pair meets WCAG AA in both themes, enforced by a scripted
contrast test (`test/theme/`), not eyeballed.

## 4. Typography

Bundled static TTFs in `lib/assets/fonts/` (no runtime fetch, no FOUT on web):

- **Inter** 400 / 500 / 600 / 700 — all UI text.
- **Cormorant Garamond** 600 — exactly two uses: dashboard hero net-worth figure and
  the auth/onboarding tagline. Nowhere else.

Roles (revalued in `app_text_styles.dart`, still mapped onto the M3 `TextTheme`):

| Role | Spec | Use |
|---|---|---|
| `display` | Inter 700 · 32/1.15 · −0.02em | page titles |
| `headline` | Inter 600 · 24/1.3 | screen sections |
| `title` | Inter 600 · 18/1.3 | card & section headers |
| `body` | Inter 400 · 15/1.5 | default |
| `label` | Inter 500 · 13/1.4 | buttons, form labels |
| `caption` | Inter 400 · 12/1.4 · muted | hints, timestamps |
| `overline` | Inter 600 · 11/1.3 · UPPERCASE +0.06em | table headers, group labels |
| `numeric` | Inter + `tnum` | every data number (amounts, dates, IDs) |
| `heroSerif` | Cormorant Garamond 600 · 40/1.1 | hero figure + tagline only |

Headings and primary actions at weight 600. No inline font sizes in widgets.

## 5. Surfaces & components

Core primitives built in PR1 under `lib/widgets/core/`:

- **`AppCanvas`** (replaces `GlassBackground`): `bg` fill + one very faint radial gold
  wash from the top (~0.05 light / ~0.04 dark, static). The only decorative gradient
  in the app.
- **`AppCard`** (replaces `GlassContainer`): opaque `surface`, hairline `border`,
  radius 16, `shadowLow`. No blur, no glow.
- **Hero balance card:** flat navy-900 (light) / `surface` (dark), 1px gold hairline
  border, `overline` label in gold-300, net worth in `heroSerif` gold-300. No gradient.
- **`StatusBadge`:** pill + filled dot, always a full quartet.
- **`MetricDelta`:** ▲/▼ + % in success/error.
- **`MeanderDivider`:** Greek-key hairline via `CustomPainter`, `border`-tone with one
  gold-200 segment.
- **`EmptyState`:** icon + title + caption + one gold CTA.
- **`AppSkeleton`:** neutral pulse, reduced-motion aware.

Component rules (via `ThemeData` themes so Material call-sites restyle automatically):

- **Primary button:** gold fill + `onGold` label, 44px, radius 12, hover `goldHover`,
  press 1px translate. **Ghost:** surface + `borderStrong` + navy text. **Text:**
  navy-600. **Destructive:** error quartet.
- **Inputs:** 44px, hairline `borderStrong`, radius 10, stacked muted label + caption
  hint; focus = 2px gold border + gold halo @ 0.18. Keyboard-visible on web.
- **Chips/filters:** `surfaceSubtle` + navy text; selected = `goldWeak` fill + gold
  hairline + `goldText`.
- **Navigation:** web/wide = `surface` top bar, hairline bottom border, full logo
  lockup left (logo · thin vertical divider · section name in muted `label` 600),
  items navy-600, active = navy-900 + 2px gold underline. Mobile = standard bottom
  `NavigationBar`, active = `goldWeak` indicator pill behind navy-900 icon (no
  gold-on-white icons). FAB = gold fill, navy icon, `shadowMedium`.
- **In-screen app bars:** transparent on canvas, navy title, hairline on scroll-under.
- **Data display:** rows 48px (40px dense), hairline dividers, last row borderless,
  subtle hover tint on web, amounts right-aligned `numeric`, sticky headers in
  `overline` on `surfaceSubtle`.
- **Elevation:** `low` / `medium` / `high` neutral sets. `brandGlow`, `fabGlow`,
  `floatingNav` glows are deleted with the shims.

## 6. Branding & Greek motif

**Full logo** (room to breathe, clear space ≥ 50% logo height, plain backgrounds only):
login/auth (centered above tagline), web top-bar lockup, web splash (navy-950 bg,
centered logo, thin gold progress hairline; `manifest.json` + `theme-color` → navy),
user-selection header.

**Icon** (tight spaces): favicon, in-app loading states, empty-state markers, settings
About row. Never stretched or recolored.

**Motif — discoverable, not costume:**

- `MeanderDivider` between report sections and settings groups.
- Coin/cornucopia line icons for wealth empty states (`textMuted` + one gold dot).
- Laurel line-icon on success moments (backup complete, report exported).
- Tagline in `heroSerif`, via `AppLocalizations`: EN "Where wealth gathers." /
  VI "Nơi tài sản sinh sôi."

All user-facing strings added by the redesign go through `AppLocalizations` (EN + VI).

## 7. Per-screen changes

All screens: migrate to `context.tokens`, remove hardcoded colors, calm layout
(whitespace, hierarchy, max one gold moment per view), routes/providers untouched.

| Screen | Notes |
|---|---|
| Login | Narrow centered column (~420px web) on `AppCanvas`; logo + tagline; Google button keeps Google branding; secondary actions ghost |
| User selection | Logo header; profile cards as `AppCard`; gold ring = selected/hover avatar |
| Main navigation | Section-5 nav chrome; keep shared-axis tab motion |
| Dashboard | Hero net-worth card (signature moment); all widgets calm `AppCard`s under one-accent policy; charts on restrained palette; staggered entrance |
| Transaction history | Dense table: 40px rows, hairlines, right-aligned `numeric`, `MetricDelta`, `goldWeak` filter chips |
| Import transactions | Calm stacked forms across 3 tabs; AI-suggested category = gold dot + `goldWeak` wash; dense preview table |
| Insights | Categorical palette; heatmap on gold ramp; coaching tips as `info` cards |
| Investment list | Portfolio total in gold `numeric`; `MetricDelta` rows; cornucopia empty state |
| Investment detail | Navy-700 price chart + gold reference line; calm sheets (radius 20, `shadowHigh`) |
| Report config | Selectable chips for sections; stacked calm fields |
| Report preview | `MeanderDivider` between sections; `overline`+`title` headers; laurel on export success |
| Backup history | Status-badge timeline; laurel on success; destructive restores in error quartet + confirm |
| Settings | Grouped hairline lists; `MeanderDivider` between groups; About row = icon + version |

**Dashboard package** (`packages/dashboard/`): edit banner → navy `info` bar; drag
handles/snap glow → gold low-alpha; empty slots → dashed hairline + muted icon + gold
add affordance; edit background → faint dot grid in `border` tone. Values passed via
the package's existing style parameters — no new coupling to app theme internals.

## 8. Motion

- **Kept:** fade-through routes, shared-axis tabs, `AnimatedThemeScope` (improved by
  token lerp).
- **Added:** one orchestrated entrance per screen — rise-and-fade (10px, ~400ms,
  easeOutCubic), ~40ms stagger header → hero → cards, via `AppMotion`.
- **Micro-interactions:** 150ms hover/focus/press. No loops, no bounce.
- **Reduced motion:** `MediaQuery.disableAnimations` skips stagger and freezes
  skeleton pulses.

## 9. Verification (every PR)

1. `flutter analyze` clean (pre-existing `packages/dashboard/example` errors are
   baseline, not regressions).
2. `flutter test` green (update tests asserting old color values; fresh checkouts need
   `touch app.env` first).
3. Web build using the **amplify.yml flags** (CLAUDE.md's `--no-wasm` variant is stale).
4. Playwright screenshots of key screens, both themes, desktop + mobile widths.
5. Scripted WCAG AA contrast test over all token text/bg pairs in `test/theme/`.

## 10. Rollout — 4 phased PRs

| PR | Branch | Contents | Effect |
|---|---|---|---|
| 1 | `feat/gold-navy-tokens` | `PlutusTokens` + lerp, revalued deprecated shims, fonts, core primitives, rebuilt `ThemeData`, contrast test | Whole app re-tints via shims |
| 2 | `feat/nav-dashboard-redesign` | Nav chrome, dashboard screen + widgets → `context.tokens`, dashboard package restyle | Core experience redesigned |
| 3 | `feat/screens-redesign` | Remaining 10 screens + widgets migrated | No `AppColors` static usages left |
| 4 | `feat/web-shell-brand-cleanup` | Web splash/favicon/manifest, delete shims + glass widgets, before/after summary doc | Migration complete |

Conventional commits; surgical staging; each PR independently reviewable and green.

## 11. Deliverables recap

- Updated `lib/theme/` tokens encoding the gold/navy system (`PlutusTokens` + revalued
  constants).
- Redesigned screens/widgets consuming tokens only.
- Logo/icon placements per branding rules (app + web shell).
- Before/after summary per screen (written in PR4).
