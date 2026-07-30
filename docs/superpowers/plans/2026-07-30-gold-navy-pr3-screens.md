# Gold/Navy Redesign — PR3: Screens Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate every remaining screen, dialog, and widget off the deprecated `AppColors`/`GlassContainer` shims onto `context.tokens` and the core primitives — closing PR2's carry-forwards, unifying the report document on a fixed dark palette, and landing the spec-mandated additions (gold portfolio total, price chart, AI-suggestion wash, history filter chips) — so that after PR3 the only `AppColors` readers left are the three shim files PR4 deletes.

**Architecture:** Spec §7 rows 1-2 and 5-13 + §5/§6 components (docs/superpowers/specs/2026-07-29-gold-navy-redesign-design.md). PR1 landed tokens/primitives; PR2 migrated nav+dashboard. PR3 is consumption plus a handful of small spec-mandated feature slices that consume EXISTING data/services only. The report document (preview + 16 report/ files) migrates to a FIXED dark document palette via the `PlutusTokens.dark` static (it renders a PDF-bound artifact and must not vary with app theme); everything else uses `context.tokens`.

**Tech Stack:** Flutter (Dart ^3.9.2), Material 3, `plutus_fe_prototype` + local `dashboard` package, fl_chart, flutter_test.

## Global Constraints

- Branch `feat/screens-redesign` (exists, tracks main at e62727f). Working directory is the worktree: D:\Backup\Work\Uni\COS40005\Plutus\Plutus-FE-prototype-1\.claude\worktrees\gold-navy-screens — every shell command cd-prefixed there; file tools use absolute paths under it; `git branch --show-current` must print `feat/screens-redesign` immediately before every commit.
- Baseline: 605 tests passing; full `flutter analyze` = 73 pre-existing issues (all in packages/dashboard/example; `flutter analyze lib` = 0) — gate on no NEW issues.
- Visual layer only, with FOUR enumerated exceptions this plan authorizes because the spec mandates them and each consumes existing data/services only: (1) portfolio total on investment list via existing `InvestmentService.getTotalPortfolioValue` (Task 11); (2) price chart on investment detail from the existing price-history list (Task 12); (3) client-side type-filter chips on transaction history (Task 9); (4) AI-suggestion indicator in the file-import desktop table + `isAiSuggested` clear-on-edit reconciliation (Task 8). Nothing else touches providers, services, models, or routing.
- No new pub dependencies. Conventional commits. Stage exact paths only — never `git add -A`. Never run whole-file `dart format`.
- Every NEW user-facing string: add key+value to BOTH `'en'` (map lines 15-880) and `'vi'` (map lines 881-1746) in lib/l10n/app_localizations.dart plus a getter in the getters section (~line 1759+): `String get x => translate('x');`. Prefer existing keys; VI must be real Vietnamese, never English copies.
- **One-accent policy (spec §3/§5):** gold at most once per view (CTA / active-selected state / hero figure). Financial deltas stay green/red via `t.success.text`/`t.error.text` (text) and `t.success.dot`/`t.error.dot` (icons/fills). NOTE: `AppColors.positive(dark)` equals `success.dot` dark, NOT `success.text` dark — a `.text` swap shifts the dark-mode green slightly; that shift is INTENDED (system consistency) for amount text, and icons/fills take `.dot`.
- **The screen migration recipe** — apply wherever a task says "apply the recipe":
  1. Outer plain `GlassContainer(...)` (no `color:` arg, or `color:` with the surface members) → `AppCard(...)`. All 6 import/history GlassContainers and most others pass `opacity:` without `color:` — that opacity is INERT (glass_container.dart:62 requires both); drop it silently. `AppCard` = `t.surface` + `Border.all(t.border)` + radius 16 + `t.shadowLow`; it ADDS a light-mode hairline and drops the gold glow — that is the intended calm look, not a regression. Preserve prior padding explicitly if it differed from AppCard's `componentLg` default. A GlassContainer with `borderRadius` ≠ 16 that can't take AppCard: use `Container(decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(<r>), border: Border.all(color: t.border)))` — or an inset chip via `t.surfaceSubtle` when it sits INSIDE a card.
  2. Accent-chip `GlassContainer(color: <accent>, opacity: ...)` → quartet surface (`t.<kind>.surface` + `Border.all(t.<kind>.border)`) when the accent is semantic (success/warning/error/info/severity), else `AppCard`/`t.surfaceSubtle` per context. Selected variant: `t.goldSelectedFill` (new in Task 1) + `Border.all(color: t.gold)`.
  3. Token mapping (add `final PlutusTokens t = context.tokens;` + import `<rel>/theme/plutus_tokens.dart`): `AppColors.primary` as CTA/fill/active → `t.gold` · as emphasis text/icon → `t.goldText` (text) / `t.brandNavy` (structural icon) · `brand(b)` → same rule · `accent` → `t.goldWeak` (fill) / `t.goldText` (text) · `brandSoft` → `t.surfaceSubtle` · `success`/`error`/`warning` → `t.success.dot`/`t.error.dot`/`t.warning.dot` (fills, snackbar backgrounds, icons) or `.text` arms (text) · `positive(b)`/`negative(b)` → `t.success.text`/`t.error.text` (amount text) or `.dot` (icons) · `textPrimary(b)` → `t.text` · `textSecondary(b)` → `t.textSecondary` · `textTertiary(b)` → `t.textMuted` · `textOnLight`/`textOnDark` pairs → `t.text` · `textOnLightSecondary`/`textOnDarkSecondary` → `t.textSecondary` · `textOnLightTertiary`/`textOnDarkTertiary` → `t.textMuted` · `surfaceDark`/`menuBackground` → `t.surface` · `surfaceMidDark` → `t.surfaceSubtle` · `borderDark`/`borderLine(b)` → `t.border` · `gridLine(b)` → `t.border` · `backgroundDark` → (report document only) `PlutusTokens.dark.bg` · `chartPalette` → `t.chartCategorical` (theme-aware contexts) / `PlutusTokens.dark.chartCategorical` (report document). Kill `isDark ? Colors.white… : Colors.black…` branching with the same table.
  4. Charts: series `t.chartCategorical[i % t.chartCategorical.length]`; single-series lines `t.chartCategorical.first` (navy); the gold entry `[1]` is reserved for reference/comparison lines. `PlutusChartStyle` statics keep their `Brightness` signatures (Task 4 migrates their internals; callers unchanged; test/widgets/chart_theme_test.dart pins monthAxisLabel only).
  5. Remove every now-unused `AppColors`/`GlassContainer` import. After each task, `grep -n "AppColors\.\|GlassContainer" <files>` (plain grep alternation; ripgrep needs the unescaped `|`) must return nothing for the migrated files.
  6. Verify per task: `flutter analyze lib` (no new issues) + full `flutter test`.
- **Report document rule (Tasks 14-16):** files under lib/widgets/report/ + report_preview_screen's content area are a PDF-bound document — they use the FIXED palette `PlutusTokens.dark` accessed statically (e.g. `PlutusTokens.dark.text`, `PlutusTokens.dark.chartCategorical[i]`), NEVER `context.tokens`. No Brightness conditionals. Screen CHROME (app bars, buttons, progress, error states) in report screens still uses `context.tokens`.
- test/theme/on_accent_contrast_test.dart tests shim-only code; it stays green untouched and dies with the shims in PR4. Do not extend it.
- Reports/re-review artifacts live in the SDD workspace the controller creates; implementers write reports where dispatched.

## Locked judgment calls (decided at plan time — cite, don't re-litigate)

1. **Report document = fixed `PlutusTokens.dark`** (rationale above). Cover's 3-stop hardcoded gradient → flat `PlutusTokens.dark.heroSurface` with `heroBorder` hairline (HeroCard pattern, no gradient).
2. **Coaching tips (3 render sites):** card surfaces move to the `info` quartet per spec §7; the difficulty badge KEEPS its success/warning/error mapping via `StatusBadge` (difficulty is a distinct 3-level semantic; the spec's "info cards" clause governs the card, not the badge).
3. **Transaction history MetricDelta clause: non-applicable** (no percentage-delta data exists on transaction rows — anchor check). Do NOT invent a delta. The dense table, hairlines, right-aligned numeric, and filter chips ARE implemented.
4. **Investment detail hero:** current-value card restyles to the fixed-navy hero pattern (`t.heroSurface` + `t.heroBorder` + `t.heroLabel` eyebrow + value in `AppTextStyles.numericStyle` with fixed light ink `const Color(0xFFEDF0F7)`). NOT `heroSerif`, NOT gold — spec §4 limits Cormorant to exactly two uses (dashboard hero, tagline) and gold hero figures to net worth / portfolio total.
5. **Gold reference line** on the detail price chart = average unit cost (`inv.purchaseValue / inv.quantity`) — existing data, the recipe's designated use of `chartCategorical[1]`.
6. **Laurel motif & About-row version (anchor-guarded):** if no laurel asset/widget and no version source exist without new deps, the implementer SKIPS and records non-applicability in their report — never invents assets or adds packages.
7. **Deferred by decision:** Done-button weight stays text-only (PR2 smoke passed); pie palettes keep the gold slot (data-viz palette is spec §3.5's own design; not an accent-policy violation); savings gauge keeps its gold fill (plan-mandated in PR2, smoke-approved).

---

### Task 1: PR2 closeout — `goldSelectedFill`, theme fixes, polish batch

**Files:**
- Modify: `lib/theme/plutus_tokens.dart` (add getter), `lib/theme/app_theme.dart` (:18-19, :236, appBarTheme), `lib/screens/main_navigation_page.dart` (:123), `lib/widgets/tax_estimation_widget.dart` (:204, :695, :700, :713, :721), `lib/widgets/transaction_history_widget.dart` (:311), `lib/widgets/irr_widget.dart` (:79-83), `lib/widgets/roi_widget.dart` (:79-83), `lib/widgets/market_trending_widget.dart` (:244-246, :378, :392), `lib/widgets/upcoming_bills_widget.dart` (:456-459), `lib/widgets/budget_summary_widget.dart` (:219-238)
- Test: `packages/dashboard/test/edit_mode_settings_test.dart` (create)

**Interfaces:**
- Produces: `Color get goldSelectedFill => Color.alphaBlend(goldWeak, surface);` as a GETTER on `PlutusTokens` (computed — no new field, no lerp change; light goldWeak is opaque so the blend equals goldWeak there). Tasks 8-13 consume `t.goldSelectedFill` for every selected-state fill.

- [ ] **Step 1: Add the getter** to `PlutusTokens` with doc comment: `/// Selected-state fill: goldWeak composited over the surface so the dark low-alpha goldWeak reads as a solid chip.` Then replace the hand-rolled blend at all four sites with `t.goldSelectedFill` (delete the light/dark ternary where one wraps it): main_navigation_page.dart:123, tax_estimation_widget.dart:204, transaction_history_widget.dart:311, app_theme.dart:236.
- [ ] **Step 2: app_theme fixes** — replace `AppColors.textPrimary(brightness)`/`AppColors.textSecondary(brightness)` (:18-19) with `t.text`/`t.textSecondary` (the `t` local already exists in `_build`); remove the then-dead `app_colors.dart` import if nothing else reads it. In `appBarTheme`, add `surfaceTintColor: Colors.transparent` (kills the M3 grey scrolled-under band; spec §5: hairline on scroll-under, no tint).
- [ ] **Step 3: zero-neutral unification** — irr_widget.dart:79-83 and roi_widget.dart:79-83: zero-value color `t.text` → `t.textSecondary` (matches MetricDelta's signless-neutral idiom).
- [ ] **Step 4: market_trending alignment** — :244-246 unselected day-button labels `t.text`+weight → `selected ? t.text : t.textMuted` (keep the weight change); :378 and :392 axis labels `t.textSecondary` → `t.textMuted`.
- [ ] **Step 5: bills due-soon** — upcoming_bills_widget.dart:456-459: keep overdue = `t.error.text`; change the `daysUntilDue <= 3` branch to `t.warning.text`.
- [ ] **Step 6: tax fills to dot arms** — tax_estimation_widget.dart :695/:700 bar segments and :713/:721 legend dots: `t.success.text.withValues(alpha:0.7)` → `t.success.dot` and `t.error.text.withValues(alpha:0.7)` → `t.error.dot` (drop the alpha — dots are the fill arm).
- [ ] **Step 7: budget figure reconciliation** — budget_summary_widget.dart `_SummaryTile` call sites (:225-238): Spent tile `valueColor: t.error.text` → `t.text`; Left tile conditional success/error → `t.text`. (Status signal remains in the progress bars + alert banner; matches category_budget's shipped neutral-figure idiom.)
- [ ] **Step 8: package default test** — create `packages/dashboard/test/edit_mode_settings_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dashboard/dashboard.dart';

void main() {
  test('EditModeSettings swapHighlightColor defaults to legacy green', () {
    const EditModeSettings settings = EditModeSettings();
    expect(settings.swapHighlightColor, const Color(0xFF4CAF50));
  });

  test('EditModeSettings passes a custom swapHighlightColor through', () {
    const EditModeSettings settings =
        EditModeSettings(swapHighlightColor: Color(0xFFC9970F));
    expect(settings.swapHighlightColor, const Color(0xFFC9970F));
  });
}
```

If `EditModeSettings` is not exported from `package:dashboard/dashboard.dart`, import its file directly (`package:dashboard/src/edit_mode/edit_mode_settings.dart`) — do not change the package's exports.
- [ ] **Step 9: Verify** — `cd packages/dashboard && flutter test` green; from the worktree root: `flutter analyze lib` no new issues; full `flutter test` 605 passing (no app tests pin these color choices).
- [ ] **Step 10: Commit**

```powershell
git add lib/theme/plutus_tokens.dart lib/theme/app_theme.dart lib/screens/main_navigation_page.dart lib/widgets/tax_estimation_widget.dart lib/widgets/transaction_history_widget.dart lib/widgets/irr_widget.dart lib/widgets/roi_widget.dart lib/widgets/market_trending_widget.dart lib/widgets/upcoming_bills_widget.dart lib/widgets/budget_summary_widget.dart packages/dashboard/test/edit_mode_settings_test.dart
git commit -m "fix(theme): goldSelectedFill token, calm appbar, PR2 polish closeout"
```

---

### Task 2: Report dashboard tiles (the two shim tiles — mixed-styling fix)

**Files:**
- Modify: `lib/widgets/report_export_widget.dart` (90 LOC), `lib/widgets/report_import_widget.dart` (83 LOC)

**Interfaces:**
- Consumes: `AppCard` (`../widgets/core/app_card.dart` → from lib/widgets/ root: `core/app_card.dart`), `context.tokens`.
- Produces: the dashboard grid is 100% calm cards — the last two accent-tinted tiles are gone.

- [ ] **Step 1: report_export_widget** — outer `GlassContainer(color: AppColors.error, opacity: 0.2)` (:23) → `AppCard(...)`. Icon + title `t.text`; description `t.textSecondary`; tooltip icon `t.textMuted` (replaces `textTertiary(brightness)` :57); the white/white70 inks (:37,:45,:66,:76) → `t.text`/`t.textSecondary`; the Export button relies on the themed `FilledButton`/`ElevatedButton` (drop the explicit `AppColors.error` fill at :77) — the button is this tile's only emphasis.
- [ ] **Step 2: report_import_widget** — mirror treatment (`AppColors.warning` accent :14-15,:70, `textTertiary` :48, whites :28,:36,:57,:69).
- [ ] **Step 3: Purge + verify** — recipe grep clean on both files; `flutter analyze lib`; full `flutter test`.
- [ ] **Step 4: Commit** — `git add lib/widgets/report_export_widget.dart lib/widgets/report_import_widget.dart && git commit -m "feat(widgets): calm report import/export tiles close the dashboard grid"`

---

### Task 3: Dead metadata — `WidgetMeta.color` deletion

**Files:**
- Modify: `lib/models/widget_catalog.dart`

- [ ] **Step 1: Re-verify the field is dead** — `grep -rn "\.color" lib/ test/ | grep -i "meta"` and `grep -rn "WidgetMeta(" lib/` — the ONLY `.color` reader anywhere must be none (survey-verified: sidebar stopped reading it in PR2; storage_service reads only defaultWidth/Height). If ANY live reader exists, STOP and report instead of deleting.
- [ ] **Step 2: Delete** the `final Color color;` field (:11), its constructor parameter, and all 23 `color:` arguments in the `all` list (lines 34-250). Remove the then-dead `app_colors.dart` import (18 accent members lose their last non-shim consumer) and the then-unused `material.dart` Color import if flagged.
- [ ] **Step 3: Verify** — `grep -n "AppColors" lib/models/widget_catalog.dart` → nothing; `flutter analyze lib`; full `flutter test` (no test reads WidgetMeta.color — survey-verified).
- [ ] **Step 4: Commit** — `git add lib/models/widget_catalog.dart && git commit -m "refactor(models): drop dead WidgetMeta.color and its 23 accent args"`

---

### Task 4: chart_theme internal migration + PlutusChartColors deletion

**Files:**
- Modify: `lib/widgets/chart_theme.dart` (76 LOC)

**Interfaces:**
- Produces: `PlutusChartStyle.defaultGridData(brightness)` / `lineBorderData(brightness)` keep their EXACT signatures (Brightness param — callers across dashboard/insights charts unchanged) but read tokens internally.

- [ ] **Step 1: Re-verify PlutusChartColors is unreferenced** — `grep -rn "PlutusChartColors" lib/ test/` → only chart_theme.dart itself. If any consumer remains, migrate that call site per recipe step 4 FIRST (in its own file), then proceed.
- [ ] **Step 2: Migrate the statics' internals** — inside chart_theme.dart add a private helper `PlutusTokens _tokensFor(Brightness b) => b == Brightness.dark ? PlutusTokens.dark : PlutusTokens.light;` then replace `AppColors.gridLine(brightness)` (:19) and both `AppColors.borderLine(brightness)` (:34-35) with `_tokensFor(brightness).border`. Delete the `PlutusChartColors` class (:5-9) and the `app_colors.dart` import.
- [ ] **Step 3: Verify** — `flutter test test/widgets/chart_theme_test.dart` green unmodified (pins monthAxisLabel only); `grep -n "AppColors" lib/widgets/chart_theme.dart` → nothing; `flutter analyze lib`; full `flutter test`.
- [ ] **Step 4: Commit** — `git add lib/widgets/chart_theme.dart && git commit -m "refactor(charts): tokenize PlutusChartStyle internals, delete dead PlutusChartColors"`

---

### Task 5: Login + user selection (auth surface, l10n batch, tagline)

**Files:**
- Modify: `lib/screens/login_screen.dart` (187 LOC), `lib/screens/user_selection_screen.dart` (308 LOC), `lib/l10n/app_localizations.dart`

**Interfaces:**
- Consumes: `AppCard`, `AppTextStyles.heroSerifStyle` (PR1 — read lib/theme/app_text_styles.dart for the exact name before use), `t.goldSelectedFill` (Task 1).
- Produces: l10n keys other tasks may reuse: `tagline` EN "Where wealth gathers." / VI "Nơi tài sản sinh sôi." (spec §6 verbatim).

- [ ] **Step 1: login_screen l10n** — the file has NO AppLocalizations import; add it and create keys (EN / VI): `tagline` (above), `loginWelcome` "Welcome to Plutus" / "Chào mừng đến với Plutus", `loginSubtitle` "Track spending, budgets, and investments in one place." / "Theo dõi chi tiêu, ngân sách và đầu tư ở cùng một nơi.", `loginFailedGoogle` "Sign-in failed. Please check your Google account and try again." / "Đăng nhập thất bại. Vui lòng kiểm tra tài khoản Google và thử lại.", `loginFailed` "Sign-in failed. Please try again." / "Đăng nhập thất bại. Vui lòng thử lại.", `signInWithGoogle` "Sign in with Google" / "Đăng nhập bằng Google", `continueAsGuest` "Continue as Guest" / "Tiếp tục với tư cách Khách" (+ getters). Reuse any of these that already exist — check the maps first.
- [ ] **Step 2: login_screen restyle** — `GlassContainer` (:82) → `AppCard` (keep the ~420px ConstrainedBox); logo block's `AppColors.brandSoft` (:96) → `t.surfaceSubtle`; heading `t.text`, subtitle `t.textSecondary`; ADD the tagline under the logo: `Text(l10n.tagline, style: AppTextStyles.heroSerifStyle.copyWith(color: t.goldText), textAlign: TextAlign.center)` — this is the auth surface's one gold moment and the app's second (final) Cormorant use; error banner (:126-140) → error quartet (`t.error.surface` fill + `t.error.border` + `t.error.text`); Google button keeps Google branding untouched; "Continue as Guest" becomes the themed ghost/outlined style (drop explicit colors).
- [ ] **Step 3: user_selection l10n** — keys (EN / VI): `createProfile` "Create a Profile" / "Tạo hồ sơ", `usernameLabel` "Username" / "Tên đăng nhập", `usernameHint` "Choose a username" / "Chọn tên đăng nhập", `displayNameLabel` "Display Name" / "Tên hiển thị", `displayNameHint` "Your display name" / "Tên hiển thị của bạn", `fillAllFields` "Please fill in all fields to continue" / "Vui lòng điền đầy đủ thông tin để tiếp tục", `usernameTaken` "Couldn't create your account. That username may already be taken." / "Không thể tạo tài khoản. Tên đăng nhập có thể đã tồn tại.", `switchProfile` "Switch Profile" / "Chuyển hồ sơ", `whosUsingPlutus` "Who's using Plutus?" / "Ai đang dùng Plutus?", `noProfilesFound` "No profiles found" / "Không tìm thấy hồ sơ nào", `createProfileToStart` "Create a profile to get started" / "Tạo hồ sơ để bắt đầu", `googleBadge` "Google" / "Google", `guestBadge` "Guest" / "Khách" (reuse `cancel`/`create`/`signInWithGoogle`/`continueAsGuest` keys where they exist). Wire every raw string through them.
- [ ] **Step 4: user_selection restyle** — profile rows: `GlassContainer` (:184) → `AppCard`; avatar `CircleAvatar` (:192-205): backgroundColor → `t.surfaceSubtle`, initial letter `t.brandNavy`; wrap the avatar in a ring `Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: hovered ? t.gold : t.border, width: hovered ? 2 : 1)))` driven by the row's hover state (use `InkWell(onHover:)` on the existing tap target — spec §7: gold ring = selected/hover avatar; tap still signs in immediately, no selection state invented); OAuth/Guest chips → `t.surfaceSubtle` + `t.textSecondary`; the three bottom actions: Create a Profile keeps the themed gold `ElevatedButton` (drop explicit `AppColors.primary`/white at :282-283), guest = ghost, Google sign-in = text button.
- [ ] **Step 5: Purge + verify** — recipe grep clean on both screens; `flutter analyze lib`; full `flutter test`.
- [ ] **Step 6: Commit** — `git add lib/screens/login_screen.dart lib/screens/user_selection_screen.dart lib/l10n/app_localizations.dart && git commit -m "feat(auth): calm login with heroSerif tagline and gold-ring profile hover"`

---

### Task 6: Settings screen

**Files:**
- Modify: `lib/screens/settings_screen.dart` (789 LOC), `lib/l10n/app_localizations.dart` (one key)

**Interfaces:**
- Consumes: `MeanderDivider` (lib/widgets/core/meander_divider.dart, `const MeanderDivider({this.height = 10})` — token-driven, ready).

- [ ] **Step 1: Apply the recipe** — 4 GlassContainers: :194 (accent chip `color: AppColors.primary, opacity: 0.1` — the session-expiry banner) → info quartet (`t.info.surface` + `t.info.border` + text/icon `t.info.text`); :612/:661/:712 plain cards → `AppCard`. The ~12 `AppColors.primary` reads: icons/labels per mapping (structural icons `t.brandNavy`, emphasis text `t.goldText`, CTA fills `t.gold` via themed buttons — drop explicit fills like :468-469 primary+white); `textOnLightSecondary` → `t.textSecondary`; `success` (avatar badge/link states :56,:163,:171) → `t.success.dot` fills / `.text` text; `warning` (:340,:359) → `t.warning.text`; `error` (:388,:391,:774 destructive rows/sign-out) → `t.error.text`.
- [ ] **Step 2: Grouped hairline lists + MeanderDivider** — between the existing top-level sections (Appearance / Preferences / Account), insert `const MeanderDivider()` (spec §6: meander between settings groups). Section headers → `AppTextStyles.overlineStyle.copyWith(color: t.textSecondary)` with `.toUpperCase()` at the call site.
- [ ] **Step 3: l10n** — the one raw string :398 `'Are you sure you want to sign out?'` → key `signOutConfirm` EN as-is / VI "Bạn có chắc chắn muốn đăng xuất?".
- [ ] **Step 4: About row (anchor-guarded)** — IF the file already renders a version/About row, restyle it (icon chip `t.surfaceSubtle` + `Image.asset` app icon + version `t.textMuted`). If none exists AND no version constant exists in the repo (`grep -rn "appVersion\|version" lib/config/ lib/main.dart` — look for an existing string constant; package_info is NOT a dep), SKIP and record non-applicability in your report.
- [ ] **Step 5: Purge + verify** — recipe grep clean; `flutter analyze lib`; full `flutter test`.
- [ ] **Step 6: Commit** — `git add lib/screens/settings_screen.dart lib/l10n/app_localizations.dart && git commit -m "feat(settings): grouped hairline lists with meander dividers on tokens"`

---

### Task 7: Backup history + the three system dialogs

**Files:**
- Modify: `lib/screens/backup_history_screen.dart` (162 LOC), `lib/widgets/backup_found_dialog.dart` (50), `lib/widgets/conflict_dialog.dart` (100), `lib/widgets/consent_dialog.dart` (247)

**Interfaces:**
- Consumes: `StatusBadge` (`core/status_badge.dart`, `StatusBadge({required StatusKind kind, required String label})`).

- [ ] **Step 1: backup_history** — rows: `GlassContainer` (:118) → `AppCard`; `AppColors.primary` (:87,:126) → `t.brandNavy` (icons). Status-badge timeline (spec §7): each backup row gains `StatusBadge(kind: StatusKind.success, label: <existing timestamp/size caption stays as text — the badge labels the backup state>)` — if rows carry no state distinction (all completed), one success badge per row is the timeline treatment; restore tap keeps its confirm dialog and the confirm's destructive action renders `t.error.text`. Laurel on restore success (anchor-guarded per Locked call #6): if no laurel asset exists, skip + record.
- [ ] **Step 2: backup_found_dialog + conflict_dialog** — delete the `isDark ?` branching entirely: `AlertDialog(backgroundColor: t.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet), side: BorderSide(color: t.border)))`; title icons `AppColors.accent`/`primary` (:31) → `t.goldText`, conflict's `accent`/`warning` (:48) → `t.warning.text`; body text `t.text`/`t.textSecondary`; destructive/confirm actions per themed buttons.
- [ ] **Step 3: consent_dialog (both dialogs inside)** — same AlertDialog treatment ×2 (:27,:195); the 12 distinct AppColors members map per the recipe table; the warning notice Container (:79-109) → warning quartet (`t.warning.surface`/`t.warning.border`/`t.warning.text`) — note :83-84's redundant ternary collapses naturally; agree buttons keep themed gold; decline `t.textSecondary` (fixes the :233 missing-dark-branch bug by construction).
- [ ] **Step 4: Purge + verify** — recipe grep clean on all four files; `flutter analyze lib`; full `flutter test` (test/providers/terms_consent_test.dart is logic-only — must stay green untouched).
- [ ] **Step 5: Commit** — `git add lib/screens/backup_history_screen.dart lib/widgets/backup_found_dialog.dart lib/widgets/conflict_dialog.dart lib/widgets/consent_dialog.dart && git commit -m "feat(backup): status-badge timeline and calm token dialogs"`

---

### Task 8: Import tabs + AI-suggestion treatment

**Files:**
- Modify: `lib/screens/import/file_import_tab.dart` (287), `lib/screens/import/manual_import_tab.dart` (612), `lib/screens/import/scan_import_tab.dart` (436), `lib/widgets/import/ai_category_field.dart`, `lib/widgets/import/file_preview_table.dart`, `lib/l10n/app_localizations.dart`
- Create: `lib/widgets/import/import_feedback.dart` (snackbar helper)
- Tests: `test/widgets/import/ai_category_field_test.dart`, `test/widgets/import/file_preview_table_test.dart` (extend minimally if they pin the old styling; record every change)

**Interfaces:**
- Produces: `void showResultSnackBar(BuildContext context, String message, {required bool isError})` in import_feedback.dart — `SnackBar(backgroundColor: isError ? t.error.dot : t.success.dot, content: Text(message, style: const TextStyle(color: Colors.white)))` — plain white content ink (both dot fills are dark enough in both themes; precedent: investment_widget retry button, blessed in PR2's final review).

- [ ] **Step 1: The shared card swap** — the byte-identical `GlassContainer(padding: EdgeInsets.all(AppSpacing.lg), borderRadius: AppRadius.lg, opacity: 0.1)` in all three tabs (file:217, manual:376, scan:242) → `AppCard(padding: const EdgeInsets.all(AppSpacing.lg))`.
- [ ] **Step 2: Snackbar helper** — create import_feedback.dart with `showResultSnackBar` and route the 7 sites through it (file:119,188,201; manual:343; scan:137,144,217,230), replacing `AppColors.success`/`error` backgrounds. Delete scan's white spinner literals (:430-431) → themed `CircularProgressIndicator` (drop explicit colors; `colorScheme.primary` is gold).
- [ ] **Step 3: AI-suggestion treatment (spec §7: gold dot + goldWeak wash)** — in ai_category_field.dart, when `isAiSuggested`: keep the existing gold border, ADD `fillColor: t.goldSelectedFill, filled: true` on the InputDecoration (the wash), and replace the `auto_awesome` suffix icon with a small gold dot: `Container(width: 8, height: 8, margin: const EdgeInsets.only(right: AppSpacing.componentSm), decoration: BoxDecoration(color: t.gold, shape: BoxShape.circle))` inside the suffix (keep it minimal — dot replaces sparkle). Runner-up ActionChips → `t.surfaceSubtle` fill + `t.textSecondary` label.
- [ ] **Step 4: file_preview_table desktop gap** — the DataTable category cell (:184-194) has NO AI indicator: wrap the DropdownButton cell in the same goldWeak wash `Container(decoration: BoxDecoration(color: t.goldSelectedFill, borderRadius: BorderRadius.circular(AppRadius.input)))` + leading 8px gold dot when that row's suggestion flag is set; AND reconcile the flag semantics — mirror the other tabs: clear the row's `isAiSuggested` when the user manually changes the category (authorized exception 4; it is UI-state only). If the table's state shape makes clear-on-edit require provider changes, implement the wash only and report the residual divergence.
- [ ] **Step 5: l10n batch** — new keys (EN / VI) for the raw strings: file tab :224 `importFromFile` "Import from File" / "Nhập từ tệp", :240 `filePrefix` "File: " / "Tệp: " (interpolate name after), :276 `importSelected` "Import Selected" / "Nhập mục đã chọn" (render count separately `'${l10n.importSelected} (${_selectedIndices.length})'`), :187 `importedSummary` "Imported {n} transactions. {m} skipped." — implement as `importedCount` "Imported" / "Đã nhập" + compose, or a full-sentence key pair if the file's l10n style prefers (`translate` supports plain keys only — compose); scan tab :260 `camera` "Camera" / "Máy ảnh", :328 `processingImage` "Processing image..." / "Đang xử lý ảnh...", :334 `extractedFields` "Extracted Fields" / "Trường đã trích xuất", :404 `items` "Items" / "Mục", :431 `confirmAndSave` "Confirm & Save" / "Xác nhận & Lưu"; form labels across tabs (`Date`/`Paid To`/`Amount`/`Currency`/`Type`/`Note`/`Item`/`New Category`/`Category name`/`Required`/`Invalid number`) — reuse existing keys where present (the import page already uses some via l10n — check the maps first), add the missing ones with real VI. Parse-error/import-error snackbars keep interpolated exceptions after an l10n prefix.
- [ ] **Step 6: Remaining token sweep** — manual :535 `primary` add-icon → `t.goldText`, :584 `error` remove-icon → `t.error.text`; scan's `Theme.of(context).colorScheme.onSurface.withValues(...)` reads (:334,:404) → `t.textSecondary`; file :278 `textOnDark` → drop with the explicit button styling (themed button).
- [ ] **Step 7: Verify** — recipe grep clean on all five lib files; `flutter test test/widgets/import/` green (if either test pinned the sparkle icon or old chip color, update the expectation minimally and record exactly what/why); `flutter analyze lib`; full `flutter test`.
- [ ] **Step 8: Commit** — `git add lib/screens/import/ lib/widgets/import/ lib/l10n/app_localizations.dart test/widgets/import/ && git commit -m "feat(import): calm tabs with gold-dot AI suggestion wash"` (only include test files actually modified).

---

### Task 9: Transaction history page + detail dialog

**Files:**
- Modify: `lib/screens/transaction_history_page.dart` (382), `lib/widgets/transaction_detail_dialog.dart` (402), `lib/l10n/app_localizations.dart`

- [ ] **Step 1: Dense table restyle** — replace the per-row `GlassContainer` cards (:175) with a hairline list: `ListView.separated`, `separatorBuilder: (_, __) => Divider(height: 1, color: t.border)`, rows as plain `InkWell` + `Padding(vertical: AppSpacing.componentSm)` targeting ≤48px visual row height (spec's dense-table direction; current cards are ~56px+): single row = leading type icon (`t.success.dot`/`t.error.dot` replacing `positive`/`negative` at :190-191), payee `t.text` with date `t.textMuted` caption beneath at 11px, amount right-aligned `AppTextStyles.numericStyle` colored `t.success.text`/`t.error.text` (:367), chevron `t.textMuted`. `Colors.grey[500]`/`Colors.grey` (:218,:234,:376) → `t.textMuted`. Export-fail snackbar `Colors.red` (:128) → `t.error.dot`. Export tooltip literal (:146) → reuse/add key `export` EN "Export" / VI "Xuất".
- [ ] **Step 2: Filter chips (authorized exception 3)** — add a chip row above the list: All / Income / Expense, client-side filter over the already-loaded transaction list (local `setState` field; no provider/service changes). Chips: unselected `t.surfaceSubtle` fill + `t.textSecondary` label; selected `t.goldSelectedFill` fill + `Border.all(color: t.gold)` + `t.goldText` label (the view's one gold moment). Keys: reuse existing `all`/`income`/`expense` l10n keys if present, else add (EN "All"/"Income"/"Expense", VI "Tất cả"/"Thu nhập"/"Chi tiêu"). MetricDelta: non-applicable per Locked call #3 — do not add.
- [ ] **Step 3: Detail dialog rebuild** — like PR2's profile rebuild: the dialog assumes dark glass (whites at :41,:49,:90,:113,:143,:149,:242,:269,:386). Outer `GlassContainer(borderRadius: 16)` (:24) → `AppCard`; inner posting rows (`GlassContainer(borderRadius: 8, opacity: 0.1)` :375) → `Container(decoration: BoxDecoration(color: t.surfaceSubtle, borderRadius: BorderRadius.circular(AppRadius.sm), border: Border.all(color: t.border)))` (8 ≠ AppCard's 16 — keep the tighter radius); all whites → `t.text`/`t.textSecondary` per role; amounts `positive`/`negative` (:263,:393) → `t.success.text`/`t.error.text`.
- [ ] **Step 4: Purge + verify** — recipe grep clean on both files; `flutter analyze lib`; full `flutter test`.
- [ ] **Step 5: Commit** — `git add lib/screens/transaction_history_page.dart lib/widgets/transaction_detail_dialog.dart lib/l10n/app_localizations.dart && git commit -m "feat(history): dense hairline table with goldWeak filter chips"`

---

### Task 10: Budget settings sheet + avatar editor

**Files:**
- Modify: `lib/widgets/budget_settings_sheet.dart` (847), `lib/widgets/avatar_editor_widget.dart` (458), `lib/l10n/app_localizations.dart`

- [ ] **Step 1: budget_settings_sheet** — sheet container (:445,:760): `colorScheme.surface` reads are fine but restyle the sheet shell per spec §5 "calm sheets": top radius `AppRadius.sheet` (20), `t.shadowHigh`, hairline top handle `t.borderStrong` (fixes the non-adaptive `textOnLightTertiary` dark-mode bug at :450); category `Card`s (:533) → `AppCard` or `t.surfaceSubtle` insets per nesting; l10n the raw strings: :117 error prefix key `errorCreatingBudget` EN "Error creating budget: " / VI "Lỗi khi tạo ngân sách: ", :698 the "… in 3 months" suffix — key `inThreeMonths` EN "in 3 months" / VI "trong 3 tháng" (compose); leave the emoji strings (:237,:253) and the `_defaultCategories` data list untouched (data refactor out of scope — note in report).
- [ ] **Step 2: avatar_editor_widget** — dialog surface `AppColors.surfaceDark` (:95) + `surfaceMidDark` (:121) + `borderDark` (:123,:205) → `t.surface`/`t.surfaceSubtle`/`t.border`; `textOnDark` reads (:105,:206,:248,:280,:402) → `t.text`; `primary` (:247,:273,:399) → `t.gold` fills / `t.goldText` text per role; keep the two painter literals (:422 black overlay, :440 white dashes — they paint OVER the user's photo, brightness-independent by design; add a one-line comment saying so); white spinner (:241) → `t.onGold` (it sits on a gold button). Delete the dead `AvatarPickerDialog.currentAvatarPath`/`defaultAvatarAsset` fields (:292-293) AND their arguments at the sole call site lib/widgets/profile_widget.dart:75-77 — re-verify with `grep -rn "currentAvatarPath\|defaultAvatarAsset" lib/` first; if other readers exist, keep and report. l10n: :226/:336 error snackbars get l10n prefixes (`avatarSaveFailed` EN "Failed to save avatar: " / VI "Không thể lưu ảnh đại diện: ", `imagePickError` EN "Error picking image: " / VI "Lỗi khi chọn ảnh: ").
- [ ] **Step 3: Verify** — `flutter test test/widgets/avatar_editor_widget_test.dart` green unmodified (logic-only, never pumps the widget); recipe grep clean on both files (+ profile_widget.dart still clean); `flutter analyze lib`; full `flutter test`.
- [ ] **Step 4: Commit** — `git add lib/widgets/budget_settings_sheet.dart lib/widgets/avatar_editor_widget.dart lib/widgets/profile_widget.dart lib/l10n/app_localizations.dart && git commit -m "feat(widgets): calm budget sheet and token avatar editor"`

---

### Task 11: Investment list + the three investment dialogs

**Files:**
- Modify: `lib/screens/investment_list_screen.dart` (359), `lib/widgets/add_investment_dialog.dart` (306), `lib/widgets/sell_investment_dialog.dart` (259), `lib/widgets/create_dashboard_dialog.dart` (166), `lib/l10n/app_localizations.dart`

**Interfaces:**
- Consumes: `MetricDelta`, `EmptyState` (PR1 — read core/empty_state.dart for its constructor), existing `IInvestmentService.getTotalPortfolioValue(List<InvestmentModel>)` via however the screen already obtains its service/investment list.

- [ ] **Step 1: Portfolio total header (authorized exception 1 — closes PR2's deferral)** — above the Active/Closed tabs add a summary strip: label `AppLocalizations` key `portfolioTotal` EN "Portfolio total" / VI "Tổng danh mục" in `overlineStyle` + `t.textSecondary`, value `getTotalPortfolioValue(<the active list the screen already holds>)` formatted with the file's existing currency formatting, styled `AppTextStyles.numericStyle.copyWith(color: t.goldText, fontSize: 24)` (spec §4 headline size) — THE gold moment of this screen (spec §7 + §3.4). No new computation beyond calling the existing service method the same way `getTotalGainLoss` already does.
- [ ] **Step 2: List restyle per recipe** — row `GlassContainer` (:272) → `AppCard`; per-row gain/loss percent → `MetricDelta(percent: ...)` where the row already shows a percentage (spec: MetricDelta rows), absolute amounts stay `t.success.text`/`t.error.text` (:266-267); `brand(brightness)` reads (:123,:166,:270) → `t.brandNavy` icons / `t.goldText` emphasis text; snackbars via `t.success.dot`/`t.error.dot` backgrounds (:96,:109); FAB explicit black/white (:157) → drop (themed FAB is gold + onGold); raw strings :95/:108/:160 → keys `investmentAdded` EN "{name} added to your portfolio" → compose "added to your portfolio" / VI "đã thêm vào danh mục của bạn", `investmentAddFailed` EN "Couldn't add investment. Please try again." / VI "Không thể thêm khoản đầu tư. Vui lòng thử lại.", reuse existing `add` key if present. Empty state → `EmptyState` primitive with `Icons.savings_outlined` (cornucopia asset does not exist — approved approximation, note in report).
- [ ] **Step 3: add_investment_dialog** — `GlassContainer(color: surfaceDark|white, blur, opacity)` (:87-91) → `AppCard`; title black87/white (:104) → `t.text`; save button explicit `primaryDark`+white (:291-292) → themed gold button; currency dropdown labels (:238-246 'VND (₫)' etc.) are data-like but user-facing — reuse the scan tab's currency labels if Task 8 created keys, else leave as symbols-only data (note in report).
- [ ] **Step 4: sell_investment_dialog** — already AlertDialog: failure snackbar `AppColors.error` (:108) → `t.error.dot`; realized gain/loss preview ternary (:205) → `t.success.text`/`t.error.text`.
- [ ] **Step 5: create_dashboard_dialog** — `GlassContainer` (:64-69) + hand-rolled border (:58-59) → `AppCard`; the textOnLight/Dark ternaries (:53-56) → `t.text`/`t.textSecondary`/`t.textMuted`; `primary` reads (:98,:124,:136,:153) → radio/checkbox inherit the themed gold; error (:102,:106) → `t.error.text`; create button explicit primary+textOnDark (:153-154) → themed.
- [ ] **Step 6: Purge + verify** — recipe grep clean on all four; `flutter analyze lib`; full `flutter test`.
- [ ] **Step 7: Commit** — `git add lib/screens/investment_list_screen.dart lib/widgets/add_investment_dialog.dart lib/widgets/sell_investment_dialog.dart lib/widgets/create_dashboard_dialog.dart lib/l10n/app_localizations.dart && git commit -m "feat(investments): gold portfolio total, MetricDelta rows, calm dialogs"`

---

### Task 12: Investment detail — tokens + the price chart

**Files:**
- Modify: `lib/screens/investment_detail_screen.dart` (532), `lib/l10n/app_localizations.dart` (chart label keys if needed)

**Interfaces:**
- Consumes: fl_chart `LineChart`, `PlutusChartStyle.defaultGridData/lineBorderData/formatCompactCurrency`, existing price-history list data (already rendered as rows at :436-460), `inv.purchaseValue`/`inv.quantity`.

- [ ] **Step 1: Hero value card** — the gradient hero (:339-374, whites + white-alpha chips) → fixed-navy hero pattern per Locked call #4: `Container(decoration: BoxDecoration(color: t.heroSurface, borderRadius: BorderRadius.circular(AppRadius.card), border: Border.all(color: t.heroBorder)))`, eyebrow label `overlineStyle` + `t.heroLabel`, current value `AppTextStyles.numericStyle` at display size in `const Color(0xFFEDF0F7)` fixed ink, ROI chip → `MetricDelta(percent: ...)` on the fixed surface (its success/error text arms read fine on navy — verify visually in Task 17's smoke).
- [ ] **Step 2: Price chart (authorized exception 2)** — inside the metrics/price section add an `AppCard`-wrapped `LineChart` ABOVE the existing price-history list (keep the list): spots = the same price-history entries already rendered (date→x by index, price→y), line color `t.chartCategorical.first`, no dots below ~30 points, grid `PlutusChartStyle.defaultGridData(brightness)`, border `lineBorderData(brightness)`, axis labels `t.textMuted` + `formatCompactCurrency`; gold reference line: `ExtraLinesData(horizontalLines: [HorizontalLine(y: inv.purchaseValue / inv.quantity, color: t.chartCategorical[1], strokeWidth: 1, dashArray: [6, 4])])` (avg unit cost — Locked call #5). Render the chart only when ≥2 price points exist; otherwise keep the list alone.
- [ ] **Step 3: Recipe sweep** — metrics `GlassContainer` (:385) → `AppCard`; price/sale rows (:440,:471, inert opacity) → hairline list rows (`t.border` dividers, `t.surfaceSubtle` only if a fill is needed); `brand` reads (:288,:302) → `t.brandNavy`; `positive`/`negative` (:319-320) → `.text` arms; `error`/`success` (:306,:398,:492) → quartet arms per role; sheet radius per spec §5 (`AppRadius.sheet`, `t.shadowHigh`) on the update-value bottom sheet if it styles its own container.
- [ ] **Step 4: Purge + verify** — recipe grep clean; `flutter analyze lib`; full `flutter test`.
- [ ] **Step 5: Commit** — `git add lib/screens/investment_detail_screen.dart lib/l10n/app_localizations.dart && git commit -m "feat(investments): navy price chart with gold cost line on calm detail"`

---

### Task 13: Insights screen + the four insights widgets

**Files:**
- Modify: `lib/screens/insights_screen.dart` (860), `lib/widgets/insights/cash_flow_forecast_widget.dart` (170), `lib/widgets/insights/coaching_tips_widget.dart` (177), `lib/widgets/insights/health_score_widget.dart` (245), `lib/widgets/insights/insights_feed_widget.dart` (135), `lib/l10n/app_localizations.dart`

- [ ] **Step 1: insights_screen** — 5 GlassContainers: 4 plain → `AppCard`; the severity accent chip (:522, `color: severityColor`) → severity quartet surface: map the existing severity value to `t.error`/`t.warning`/`t.info` and use `.surface` fill + `.border` hairline + `.text` ink (read/unread stays as the existing opacity/weight distinction, re-expressed as `t.surfaceSubtle` vs quartet surface if the code branches on read state). The ~20 `primary` reads → `t.brandNavy` (structural icons/tabs) / `t.goldText` (emphasis) / themed buttons (fills); `success`/`warning`/`error` banding → quartet arms per role; whites (:96,:106,:192,:215,:275) → `t.onGold` where on gold fills, else `t.text`. Font-size FAB labels 'A+'/'A−' (:96,:106) + tooltips (:95,:105) → keys `textSizeIncrease`/`textSizeDecrease` EN "Increase text size"/"Decrease text size" / VI "Tăng cỡ chữ"/"Giảm cỡ chữ" (labels stay 'A+'/'A−' as glyphs — not translated).
- [ ] **Step 2: Coaching = info cards (Locked call #2)** — insights_screen `_CoachingCard` (:631) AND coaching_tips_widget (:61): card surface `t.info.surface` + `Border.all(t.info.border)` + title/icon `t.info.text`, body `t.text`; `_DifficultyBadge` (:697-728) → `StatusBadge(kind: success|warning|error by difficulty, label: <existing difficulty label>)`.
- [ ] **Step 3: The other three widgets per recipe** — cash_flow_forecast: 3-scenario lines `AppColors.success/primary/error` → `t.chartCategorical[0]` (base, navy), `[1]` (optimistic, gold — a projection/reference per the palette's reserved role), `[3]` (pessimistic, teal); tooltip/legend follow; `textTertiary` → `t.textMuted`. health_score: gauge banding success/warning/error → `.dot` arms (fills) with `.text` for the score text; `primary` icon → `t.brandNavy`. insights_feed: `primary` reads → `t.brandNavy`/`t.goldText` per role; row containers `t.surfaceSubtle` + `t.border`.
- [ ] **Step 4: Purge + verify** — recipe grep clean on all five files; `flutter analyze lib`; full `flutter test`.
- [ ] **Step 5: Commit** — `git add lib/screens/insights_screen.dart lib/widgets/insights/ lib/l10n/app_localizations.dart && git commit -m "feat(insights): quartet severity cards, info coaching, calm charts"`

---

### Task 14: Report document shared idiom (fixed dark palette)

**Files:**
- Modify: `lib/widgets/report/report_section_header.dart` (47), `lib/widgets/report/report_ai_recommendation.dart` (89), `lib/widgets/report/report_metric_card.dart` (65), `lib/widgets/report/cover_section.dart` (136), `lib/l10n/app_localizations.dart`

**Interfaces:**
- Produces: the fixed-document idiom Tasks 15-16 rely on — `PlutusTokens.dark` is `static const` (plutus_tokens.dart:185, verified): each file declares `const PlutusTokens doc = PlutusTokens.dark;` at build scope and reads `doc.<token>`. `ReportSectionHeader` keeps its exact public constructor (`title`, `icon` — verify before editing).

- [ ] **Step 1: report_section_header** — the single-file MeanderDivider insertion (13 sections inherit it): replace `Divider(color: Colors.white12)` (:16-25) with `const MeanderDivider()`. Then the header block becomes exactly: `Row(icon in doc.textMuted, componentSm gap, Column(crossAxisAlignment: start, [Text(title.toUpperCase(), style: AppTextStyles.overlineStyle.copyWith(color: doc.textMuted)), Text(title, style: AppTextStyles.titleStyle.copyWith(color: doc.text))]))` — the spec's overline+title pair: uppercase eyebrow over the title, icon preserved. All whites → `doc.text`/`doc.textMuted`. Keep the public constructor (`title`, `icon`) unchanged.
- [ ] **Step 2: report_ai_recommendation** — `accentColor` default `AppColors.primary` → `PlutusTokens.dark.goldText`; the gradient/left-border callout → flat `doc.surfaceSubtle` fill + `Border(left: BorderSide(color: doc.goldText, width: 2))` + text `doc.text`/`doc.textSecondary`. Keep the `accentColor` constructor param (callers pass domain accents in Task 15 — they will all pass nothing or goldText after migration; if after Task 15 no caller passes it, remove the param THERE, not here).
- [ ] **Step 3: report_metric_card** — `GlassContainer(color: Colors.white, opacity: 0.05)` (:24) → `Container(decoration: BoxDecoration(color: doc.surfaceSubtle, borderRadius: BorderRadius.circular(AppRadius.card), border: Border.all(color: doc.border)))`; label white54 → `doc.textMuted`; value `accentColor` param stays but its default/callers move to `doc.text` (cover's 3 tiles pass accents today — Task 15 neutralizes); change row whites → `doc.textSecondary`.
- [ ] **Step 4: cover_section** — the 3-stop hex gradient (:30-32) → flat `PlutusTokens.dark.heroSurface` + `Border.all(color: PlutusTokens.dark.heroBorder)` (Locked call #1); title inks → `doc.text` fixed; 'Generated …' prefix (:125) → key `reportGeneratedPrefix` EN "Generated " / VI "Tạo lúc "; metric tiles pass `accentColor: doc.text` (headline figures are neutral in the document; the cover's gold is the heroBorder hairline).
- [ ] **Step 5: Verify** — `grep -n "AppColors\.\|GlassContainer\|Colors.white" lib/widgets/report/report_section_header.dart lib/widgets/report/report_ai_recommendation.dart lib/widgets/report/report_metric_card.dart lib/widgets/report/cover_section.dart` → nothing (Colors.white family fully replaced by doc tokens); `flutter analyze lib`; full `flutter test`.
- [ ] **Step 6: Commit** — `git add lib/widgets/report/report_section_header.dart lib/widgets/report/report_ai_recommendation.dart lib/widgets/report/report_metric_card.dart lib/widgets/report/cover_section.dart lib/l10n/app_localizations.dart && git commit -m "feat(report): fixed navy document idiom with meander section dividers"`

---

### Task 15: Report sections batch (the remaining 12)

**Files:**
- Modify: `lib/widgets/report/executive_summary_section.dart`, `spending_breakdown_section.dart`, `income_analysis_section.dart`, `cash_flow_section.dart`, `budget_actual_section.dart`, `top_merchants_section.dart`, `investment_portfolio_section.dart`, `forecast_section.dart`, `alerts_section.dart`, `coaching_section.dart`, `bills_section.dart`, `transaction_log_section.dart`, `lib/l10n/app_localizations.dart`

Apply the fixed-document mapping to every file (`final PlutusTokens doc = PlutusTokens.dark;`):
- Whites family (`Colors.white`/`white54`/`white38`/`white12`) → `doc.text` / `doc.textSecondary` / `doc.textMuted` / `doc.border` respectively.
- Domain accents (`incomeAccent`/`expenseAccent`/`savingsAccent`/`budgetAccent`/`billsAccent`/`marketAccent`/`cashflowAccent`) → the document quartets/palette: income/positive figures `doc.success.text`, expense/negative `doc.error.text`, neutral domain icons `doc.textMuted`, progress fills `doc.success.dot`/`doc.warning.dot`/`doc.error.dot` by state, generic series `doc.chartCategorical[i % 6]`.
- `AppColors.chartPalette` (spending_breakdown, top_merchants) → `doc.chartCategorical[i % doc.chartCategorical.length]`.
- `primary`/`warning` alert/CTA accents (alerts_section) → `doc.warning.text`/`doc.info.text` per severity; `ReportAiRecommendation(accentColor: ...)` call sites → drop the argument (Task 14's goldText default governs); after the last caller drops it, REMOVE the now-unused param from report_ai_recommendation.dart in this task.
- l10n: bills_section :36 `noRecurringBills` EN "No recurring bills data available" / VI "Không có dữ liệu hóa đơn định kỳ", :70 `monthlyRecurring` EN "MONTHLY RECURRING" / VI "ĐỊNH KỲ HÀNG THÁNG" (call-site uppercases — store sentence case "Monthly recurring"/"Định kỳ hàng tháng" and `.toUpperCase()`).

- [ ] **Step 1: Migrate all 12 per the mapping above** (each is 89-226 LOC with 2-11 reads — mechanical)
- [ ] **Step 2: Verify** — `grep -rn "AppColors\.\|Colors.white" lib/widgets/report/` → nothing; `flutter analyze lib`; full `flutter test`.
- [ ] **Step 3: Commit** — `git add lib/widgets/report/ lib/l10n/app_localizations.dart && git commit -m "feat(report): all sections on the fixed navy document palette"`

---

### Task 16: Report config + preview screens, export dialogs

**Files:**
- Modify: `lib/screens/report_config_screen.dart` (565), `lib/screens/report_preview_screen.dart` (241), `lib/widgets/export_dialog.dart` (418), `lib/widgets/export_preview_dialog.dart` (278), `lib/l10n/app_localizations.dart`

- [ ] **Step 1: report_config** — 6 plain GlassContainers → `AppCard`; section-toggle chips/rows: selected = `t.goldSelectedFill` + `Border.all(t.gold)` + `t.goldText` (spec: selectable chips), unselected `t.surfaceSubtle` + `t.textSecondary`; `SegmentedButton`s inherit the theme (drop explicit fills); `textPrimary`/`textSecondary`/`borderLine` reads per table; `surfaceDark` (:263) → `t.surface`; progress overlay (:530) → `AppCard` + `t.text` + gold progress (themed).
- [ ] **Step 2: report_preview** — screen CHROME on `context.tokens` (`AppBar` inherits, error state `t.error.text` :123/:235, retry themed); the document CANVAS area: scaffold body behind the sections `PlutusTokens.dark.bg` (:34 backgroundDark), progress-bar track hex `0x1FFFFFFF` (:105) → `PlutusTokens.dark.surfaceSubtle`, progress fill `PlutusTokens.dark.goldText`; `textOnDark*` reads inside the document header/footer → `PlutusTokens.dark.text`/`.textSecondary`/`.textMuted`; success/export affordances (:220) → `PlutusTokens.dark.success.text`; error text prefix (:126) → key `errorPrefix` EN "Error: " / VI "Lỗi: ". Laurel on export success: anchor-guarded (Locked call #6) — no asset exists, skip + record.
- [ ] **Step 3: export_dialog** — 2 plain GlassContainers → `AppCard` (outer keeps radius 16; inner date-range card radius 8 → `t.surfaceSubtle` container); option-card selection states: selected `t.goldSelectedFill` + `t.gold` hairline + `t.goldText`, unselected `t.surfaceSubtle`/`t.textSecondary` (:280-341 region); `error` destructive bits `t.error.text`.
- [ ] **Step 4: export_preview_dialog l10n + tokens** — the cluster's only unlocalized file: keys (EN / VI): `exportPreview` "Export Preview" / "Xem trước bản xuất", `pdfNotAvailable` "PDF document not available for preview" / "Không thể xem trước tài liệu PDF", `textNotAvailable` "Text content not available for preview" / "Không thể xem trước nội dung văn bản", `openExternalApp` "Open in External App" / "Mở bằng ứng dụng khác", `fileLocation` "File Location" / "Vị trí tệp", `couldNotOpenFile` "Could not open file: " / "Không thể mở tệp: ", `errorOpeningFile` "Error opening file: " / "Lỗi khi mở tệp: " (reuse existing `done` key). Tokens: 2 GlassContainers → `AppCard`/`t.surfaceSubtle`; format icon `error`/`primary` (:71-72,:223) → `t.error.text`/`t.brandNavy`; `warning` (:260) → `t.warning.text`; `Colors.black` (:164) preview scrim → `t.text.withValues(alpha: 0.55)` only if it scrims content, else `Colors.black54` stays with a comment (judge in place: if it overlays a rendered PDF page, brightness-independent black is correct — comment it).
- [ ] **Step 5: Purge + verify** — recipe grep clean on all four files; `flutter analyze lib`; full `flutter test`.
- [ ] **Step 6: Commit** — `git add lib/screens/report_config_screen.dart lib/screens/report_preview_screen.dart lib/widgets/export_dialog.dart lib/widgets/export_preview_dialog.dart lib/l10n/app_localizations.dart && git commit -m "feat(report): calm config chips, fixed navy preview canvas, localized export dialogs"`

---

### Task 17: Verification sweep

**Files:** none (verification only)

- [ ] **Step 1:** THE PR3 EXIT CRITERION — `grep -rln "AppColors\." lib/ --include="*.dart"` must return EXACTLY three files: `lib/theme/app_colors.dart`, `lib/widgets/glass_container.dart`, `lib/widgets/glass_background.dart` (the shims PR4 deletes). `grep -rln "GlassContainer" lib/ --include="*.dart" | grep -v glass_container.dart` must return only `lib/widgets/core/app_card.dart` (doc comment). Record both outputs.
- [ ] **Step 2:** `flutter analyze` → no issues beyond the 73-issue baseline. `flutter test` → all green (605 + Task 1's 2 package tests + anything added; record the exact count).
- [ ] **Step 3:** `flutter build web --release --no-tree-shake-icons --source-maps --dart-define=FLUTTER_WEB_AUTO_DETECT=true --dart-define-from-file=app.env` → succeeds.
- [ ] **Step 4: Visual smoke** (controller-run: serve `build/web` statically, Playwright at 1280px + 390px, light + dark, guest profile — seed transactions via the manual import flow as in PR2's smoke):
  - Login + user-selection: tagline serif gold, calm cards, gold ring on avatar hover (1280 web), no legacy wash.
  - Settings: meander dividers, quartet session banner, calm groups. Backup dialogs if reachable.
  - Import tabs: AppCard forms; AI wash + gold dot on suggested category (manual tab, type a known payee); themed snackbars.
  - Transaction history page: dense hairline rows, filter chips (gold selected), themed detail dialog.
  - Investments: gold portfolio total on list; detail hero navy card + price chart with gold dashed cost line (needs ≥2 price points — update value once via the sheet).
  - Insights: quartet severity/coaching cards, calm charts.
  - Report config chips + preview: fixed navy document, meander between sections, neutral cover.
  - AppBar scroll: NO grey band (Task 1's surfaceTint fix), hairline only.
  - Theme toggle + both widths: no overflow stripes anywhere.
- [ ] **Step 5:** Fix anything broken; re-run affected tests; commit fixes with `fix(...)` messages.

---

### Task 18: Push + open PR

- [ ] **Step 1:** `git push -u origin feat/screens-redesign`
- [ ] **Step 2:** `gh pr create --base main` — title `feat(screens): calm gold/navy across all remaining surfaces (redesign PR3)`; body per repo convention (Summary bullets / Verification evidence / Next: PR4 web shell + shim deletion), flagging: the fixed-document palette decision, the four authorized feature slices (portfolio total closes PR2's deferral, price chart, filter chips, AI-wash), the anchor-guarded skips actually taken (laurel/About/etc. per implementer reports), and the exit-criterion grep outputs.
- [ ] **Step 3:** Report the PR URL.

---

## Plan self-review record

- **Spec coverage (PR3 = §7 rows Login/User-selection/Transaction-history/Import/Insights/Investment-list/Investment-detail/Report-config/Report-preview/Backup/Settings + §5 sheets/inputs/chips + §6 tagline/meander + §10 row 3 exit criterion):** login+tagline (T5), user selection + gold ring (T5), settings + meander + About-guarded (T6), backup timeline + dialogs (T7), import + AI wash (T8), history dense table + chips + detail dialog (T9), budget sheet + avatar (T10), investment list + gold total + EmptyState (T11), investment detail + chart + gold reference (T12), insights + info coaching (T13), report document idiom + meander + cover (T14), sections (T15), config/preview/export dialogs + l10n (T16), exit-criterion grep + smoke (T17), PR (T18). PR2 closeout: goldSelectedFill/appbar tint/zero-neutral/market idiom/tax dots/bills warning/budget figures/package test (T1), report tiles first (T2), WidgetMeta.color (T3), chart_theme (T4).
- **Placeholder scan:** all mappings carry exact members/lines from the four survey reports; anchor-guarded items (laurel, About row, currency labels, clear-on-edit reach) specify the guard and the skip-and-record path — no TBDs.
- **Type consistency:** `goldSelectedFill` (T1 getter) consumed T5/T8/T9/T16 by that exact name; `PlutusTokens.dark` static confirmed to exist (used by PR1/PR2 tests); `StatusBadge(kind:, label:)`, `MetricDelta(percent:, decimals:)`, `MeanderDivider({height})`, `EmptyState` signatures verified or flagged to read-before-use; `showResultSnackBar(context, message, {required bool isError})` defined T8 and used only there.
- **Known judgment calls:** the seven Locked calls above, plus: report document intentionally keeps `PlutusTokens.dark` even in light app theme (document ≠ UI); dark-green shade shift from positive→success.text documented as intended; snackbar white ink on dot fills follows PR2's blessed precedent.
- **Deliberately unassigned spec item (flag in the PR body):** spec §5's web/wide top-bar navigation (logo lockup + gold underline active items) is implemented by NO PR — PR2 made the documented call to keep the retokenized floating bottom bar at all widths. Owner to decide: fold into PR4 or accept the shipped nav. Not silently dropped.
