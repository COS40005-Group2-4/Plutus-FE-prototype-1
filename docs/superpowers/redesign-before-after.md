# Gold/Navy Redesign: Before/After Summary

Palette: navy structure (bg/surface/text) with gold as the one signature accent per view
(hero figures, active states — never up/down signals); status quartets (success/warning/
info/error) carry all financial/status signals. Report document is a fixed `PlutusTokens.dark`
palette regardless of app theme.

| Surface | Before (legacy idiom) | After (gold/navy idiom) | PR |
|---|---|---|---|
| Nav chrome (bottom bar + sidebar) | `GlassContainer` glass bar/drawer, per-item `meta.color` tinting | Hairline surface bar, `goldWeak` pill + navy icon, gold FAB; calm drawer, `HeroCard` header, one-accent tiles (`MenuItemData` deleted) | 36 |
| Dashboard shell (grid + edit mode) | `GlassBackground` gradient wash, `MySlotBackground`, hardcoded green swap highlight | `AppCanvas` faint gold radial wash, token slot chrome, gold edit glow/handles, staggered `EntranceReveal` (`MySlotBackground` deleted) | 36 |
| Hero net-worth card | Plain net-worth tile, no signature moment | `HeroCard` flagship — navy card, `heroSerif` gold figure | 36 |
| `packages/dashboard` edit mode | Hardcoded green swap-highlight color, hardcoded info banner styling | New optional `EditModeSettings.swapHighlightColor`, app passes `t.gold`; edit banner on the info quartet | 36 |
| Budget widget | `GlassContainer` card, ad hoc colors | `AppCard` pair, token figures ("Left" tile kept neutral by design; status lives in bars/banner) | 36 |
| Bills widget | Glass card, custom status coloring | `AppCard` + `StatusBadge` quartet | 36 |
| Tax widget | Glass card, custom status coloring | `AppCard` + `StatusBadge` quartet | 36 |
| Investments widget (dashboard grid) | Glass card, plain deltas | `AppCard` + `MetricDelta` rows (gold portfolio total deferred to Investment List screen) | 36 |
| Trends widget | Glass card, hardcoded chart colors | `AppCard`, token categorical palette | 36 |
| Breakdown/chart widgets | Glass card, `PlutusChartColors` palette | `AppCard`, token categorical palette (`PlutusChartColors` deleted) | 36, 37 |
| Heatmap widget | Custom color ramp, glass card | `AppCard`, `t.heatmapRamp` + hairline cells | 36 |
| History card widget | Glass card | `AppCard`, calm layout | 36 |
| Profile widget | Glass card, dead `profile` param | `AppCard`, calm layout; dead param dropped | 36, 4 |
| Login screen | Custom glass form, no signature branding | `AppCanvas` narrow column, logo + `heroSerif` tagline, ghost secondary actions | 37 |
| User selection screen | Glass profile cards | Logo header, `AppCard` profiles, gold-ring selected/hover avatar | 37 |
| Settings screen | Glass grouped list | Hairline grouped lists, `MeanderDivider` between groups, info-quartet session banner | 37 |
| Backup history + dialogs | Glass timeline, ad hoc dialog styling | `StatusBadge` timeline, error-quartet destructive confirm dialogs | 37 |
| Import tabs | Glass forms, plain AI-suggestion highlight | Calm stacked forms, gold dot + `goldWeak` AI-suggestion wash, dense preview table | 37, 4 |
| Transaction history page | Glass list, no dense table | Dense hairline table, right-aligned `numeric`, `MetricDelta`, `goldWeak` filter chips | 37 |
| Transaction detail dialog | Glass dialog | `AppCard` dialog, token chrome | 37 |
| Budget sheet | Glass bottom sheet | Calm sheet, radius 20, `shadowHigh` | 37 |
| Avatar editor | Glass editor sheet | Token chrome, gold-ring preview | 37 |
| Investment list screen | Glass list, plain total | Gold `numeric` portfolio total, `MetricDelta` rows, `Icons.savings_outlined` empty state (cornucopia asset doesn't exist) | 37 |
| Investment detail screen | Glass detail, no price chart | Navy price chart + gold average-cost reference line, calm sheets; sparse-series dot fix | 37, 4 |
| Investment dialogs (buy/sell/edit) | Glass dialogs | `AppCard`/token dialogs | 37 |
| Insights screen + widgets | Glass cards, ad hoc heatmap colors | Categorical palette, gold-ramp heatmap, info-quartet coaching tips; gold-ring period chips | 37, 4 |
| Report cover | Palette followed app theme, per-section tinting | Fixed `PlutusTokens.dark`, flat `heroSurface` + gold `heroBorder` hairline, neutral accent bar | 37 |
| Report sections | Per-domain accent tints (market/bills) | `MeanderDivider` between sections, `overline`+`title` headers (domain tinting intentionally dropped) | 37 |
| Report config | Glass form | Selectable chips, stacked calm fields | 37 |
| Report preview | Glass preview, theme-following | Dark-token document canvas, Theme-wrapped so context primitives resolve dark tokens | 37 |
| Report export | Plain success toast | Token success snackbar (laurel motif skipped — no asset exists) | 37 |
| Web shell (splash/favicon/manifest) | Default Flutter splash/favicon, no theme-color | Navy-950 splash, centered logo + gold progress hairline, `theme-color` → navy | 4 |
| Shim deletion + status-fill ink | Deprecated `AppColors`/`AppElevation`/`AppGradients`/`GlassContainer`/`GlassBackground` still live; ad hoc white-on-`.dot` ink at each call site | Shims deleted entirely; app runs on `PlutusTokens` + core primitives only; `AppMotion` extracted; new `onStatus` token consolidates status-fill ink | 4 |

**Open item:** spec §5's web/wide top-bar navigation (full logo lockup + underline-active top
bar) was never built — the retokenized bottom `NavigationBar` was kept at all widths through
PR2–PR4; unassigned as of this doc.
