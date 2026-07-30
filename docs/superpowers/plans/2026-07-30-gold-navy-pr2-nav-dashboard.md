# Gold/Navy Redesign — PR2: Nav + Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate the core experience — app canvas, navigation chrome, sidebar, dashboard screen, edit-mode chrome, and all 19 dashboard widgets — off the deprecated `AppColors`/`GlassContainer` shims onto `context.tokens` and the `lib/widgets/core/` primitives, mounting the HeroCard net-worth moment and collapsing per-widget accents into the calm gold/navy system.

**Architecture:** Spec §7 (docs/superpowers/specs/2026-07-29-gold-navy-redesign-design.md). PR1 landed the tokens and primitives; PR2 is consumption. Widget migration follows one uniform recipe (Global Constraints below) applied per widget cluster; nav/sidebar/dashboard chrome are bespoke retokenizations; the dashboard package is restyled almost entirely through its existing constructor parameters plus one new optional parameter for the hardcoded swap-highlight color. Four carry-forwards from PR1's final review are folded in (AppCanvas wiring+test, MetricDelta zero-delta, StatusBadge 4-arm test, textMuted usage rule).

**Tech Stack:** Flutter (Dart ^3.11), Material 3, `plutus_fe_prototype` + local `dashboard` package, fl_chart, flutter_test.

## Global Constraints

- Branch `feat/nav-dashboard-redesign` (exists, tracks origin/main at 2959a8a). Working directory is the worktree: D:\Backup\Work\Uni\COS40005\Plutus\Plutus-FE-prototype-1\.claude\worktrees\gold-navy-tokens — every shell command cd-prefixed there; file tools use absolute paths under it; `git branch --show-current` must print `feat/nav-dashboard-redesign` immediately before every commit.
- Visual layer only: no changes to providers, services, models, routing, or business logic. The `_DirectionalAxisSwitcher` tab motion, `AnimatedThemeScope`, and route transitions are KEPT untouched (spec §8).
- Baseline: 597 tests passing; `flutter analyze` = 73 pre-existing issues (packages/dashboard/example) — gate on no NEW issues.
- No new pub dependencies. Conventional commits. Stage exact paths only — never `git add -A`.
- Every NEW user-facing string: add key+value to BOTH `'en'` (~line 15) and `'vi'` (~line 880) maps in lib/l10n/app_localizations.dart plus a getter (`String get x => translate('x');`). Prefer existing keys; VI translations must be real Vietnamese, not English copies.
- **One-accent policy (spec §3/§5):** dashboard widgets LOSE their per-widget accent tints. Gold appears at most once per view (CTA / active state / hero figure). Financial deltas stay green/red via `t.success.text`/`t.error.text`.
- **The widget migration recipe** — apply wherever a task says "apply the recipe":
  1. Outer `GlassContainer(color: <xAccent>, opacity: 0.2, ...)` → `AppCard(...)` (import `../core/app_card.dart` or `../../widgets/core/app_card.dart` as pathing requires). Drop the accent argument entirely. Preserve existing padding/margin/width/height arguments; `AppCard` defaults padding to `componentLg` — pass the widget's previous padding explicitly if it differed.
  2. Inner `GlassContainer(color: <onAccent/other>, opacity: 0.05–0.1/0.3, borderRadius: r)` chip surfaces → `Container(decoration: BoxDecoration(color: t.surfaceSubtle, borderRadius: BorderRadius.circular(r), border: Border.all(color: t.border)))`. A "selected" variant (`transaction_history_widget`) uses `color: <light: t.goldWeak / dark: Color.alphaBlend(t.goldWeak, t.surface)>` with `Border.all(color: t.gold)`.
  3. Token mapping (add `final PlutusTokens t = context.tokens;` + `import '<rel>/theme/plutus_tokens.dart';`):
     `AppColors.onAccentPrimary(a,b)` → `t.text` · `onAccentSecondary` → `t.textSecondary` · `onAccentTertiary`/`iconOnAccent` → `t.textMuted` · `iconOnAccentEmphasis` → `t.text` · `dividerOnAccent` → `t.border` · `progressTrackOnAccent` → `t.surfaceSubtle` · `AppColors.positive(b)` → `t.success.text` · `negative(b)` → `t.error.text` · `success` → `t.success.dot` (fills) or `t.success.text` (text) · `error` → `t.error.dot`/`t.error.text` likewise · `warning` → `t.warning.dot`/`t.warning.text` · `textPrimary(b)` → `t.text` · `textSecondary(b)` → `t.textSecondary` · `textTertiary(b)` → `t.textMuted` · `AppColors.primary`/`brand(b)` used as emphasis → `t.goldText` (text) or `t.gold` (fill/active) · `surfaceDark`/`menuBackground` → `t.surface` · `borderDark` → `t.border` · `accent` (gold-100 chip fill) → `t.goldWeak`.
  4. Chart series colors: replace `PlutusChartColors.get(i)` / `PlutusChartColors.palette[i]` with `t.chartCategorical[i % t.chartCategorical.length]`; single-series lines use `t.chartCategorical.first` (navy) with the gold entry `t.chartCategorical[1]` reserved for reference/comparison lines. `PlutusChartStyle.defaultGridData/defaultBorderData/lineBorderData/formatCompactCurrency/monthAxisLabel` stay as-is (behavior pinned by test/widgets/chart_theme_test.dart).
  5. Remove the widget's `const accent = AppColors.<x>Accent` (or inline reads) and every now-unused `AppColors`/`GlassContainer` import. After each task `grep -n "AppColors\.\|GlassContainer" <files>` must return nothing for the migrated files.
  6. Verify per task: `flutter analyze lib` (no new issues) + full `flutter test`.
- test/theme/on_accent_contrast_test.dart tests shim-only code after migration; it stays green untouched (computed, not pinned) and dies with the shims in PR4. Do not extend it.
- Reports/re-review artifacts live in the SDD workspace the controller creates; implementers write reports where dispatched.

---

### Task 1: Wire `AppCanvas` + widget test (carry-forward)

**Files:**
- Modify: `lib/main.dart:155-159`
- Test: `test/widgets/core/app_canvas_test.dart` (create)

**Interfaces:**
- Consumes: `AppCanvas` (lib/widgets/core/app_canvas.dart, PR1), `AnimatedThemeScope` (republishes lerped ThemeData incl. PlutusTokens — verified).
- Produces: the app paints the calm canvas (t.bg + faint gold wash) everywhere; `GlassBackground` has zero live call-sites (delete in PR4).

- [ ] **Step 1: Write the failing test**

Create `test/widgets/core/app_canvas_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/theme/app_theme.dart';
import 'package:plutus_fe_prototype/theme/plutus_tokens.dart';
import 'package:plutus_fe_prototype/widgets/core/app_canvas.dart';

void main() {
  testWidgets('AppCanvas paints bg, a pointer-transparent wash, and SafeArea child',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: const AppCanvas(child: Text('content')),
    ));

    final ColoredBox base = tester.widget<ColoredBox>(find
        .descendant(of: find.byType(AppCanvas), matching: find.byType(ColoredBox))
        .first);
    expect(base.color, PlutusTokens.light.bg);
    expect(
        find.descendant(
            of: find.byType(AppCanvas), matching: find.byType(IgnorePointer)),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byType(AppCanvas), matching: find.byType(SafeArea)),
        findsOneWidget);
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('AppCanvas wash follows theme brightness',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      home: const AppCanvas(child: SizedBox()),
    ));
    final Container wash = tester.widget<Container>(find
        .descendant(
            of: find.byType(IgnorePointer), matching: find.byType(Container))
        .first);
    final RadialGradient g =
        (wash.decoration! as BoxDecoration).gradient! as RadialGradient;
    expect(g.colors.first.a, closeTo(0.04, 0.005));
  });
}
```

- [ ] **Step 2: Run to verify it fails** — `flutter test test/widgets/core/app_canvas_test.dart` → the file is new; it should PASS immediately against the existing AppCanvas EXCEPT nothing verifies wiring — so this test passes pre-wiring. That is fine: it is the carry-forward coverage test. Run it; expect PASS (2 tests). (The wiring itself is verified by Step 4's grep + the Task 14 smoke.)

- [ ] **Step 3: Swap the canvas in main.dart**

In `lib/main.dart`, replace the builder body (lines 155-159):

```dart
      builder: (BuildContext context, Widget? child) {
        return AnimatedThemeScope(
          child: AppCanvas(child: child!),
        );
      },
```

Update imports: remove the `glass_background.dart` import; add `import 'widgets/core/app_canvas.dart';`.

- [ ] **Step 4: Verify** — `grep -rn "GlassBackground" lib/` → only the deprecated definition file itself. `flutter test` → 599 (597 + 2). `flutter analyze lib` → no new issues.

- [ ] **Step 5: Commit**

```powershell
git add lib/main.dart test/widgets/core/app_canvas_test.dart
git commit -m "feat(canvas): wire AppCanvas as the app-wide calm canvas"
```

---

### Task 2: Core polish — MetricDelta zero-delta, StatusBadge 4-arm test, EntranceReveal, textMuted rule

**Files:**
- Modify: `lib/widgets/core/metric_delta.dart`, `lib/theme/plutus_tokens.dart` (doc comment only), `test/widgets/core/status_badge_test.dart`
- Create: `lib/widgets/core/entrance_reveal.dart`
- Test: `test/widgets/core/entrance_reveal_test.dart` (create)

**Interfaces:**
- Produces: `MetricDelta` renders exact-zero as a signless neutral (`0.0%` in `t.textSecondary`, no arrow); `class EntranceReveal extends StatefulWidget { const EntranceReveal({super.key, required this.index, required this.child}); final int index; final Widget child; }` — rise-and-fade 10px/400ms with 40ms×index stagger, skipped under `MediaQuery.disableAnimations` (spec §8). Tasks 5/7 consume `EntranceReveal`.

- [ ] **Step 1: Write the failing tests**

Append to `test/widgets/core/status_badge_test.dart` (inside `main`, after the existing tests — reuse the file's existing `pump` helper):

```dart
  testWidgets('StatusBadge renders every quartet arm from tokens',
      (WidgetTester tester) async {
    const Map<StatusKind, String> labels = <StatusKind, String>{
      StatusKind.success: 'ok',
      StatusKind.warning: 'careful',
      StatusKind.info: 'fyi',
      StatusKind.error: 'bad',
    };
    for (final MapEntry<StatusKind, String> e in labels.entries) {
      await pump(tester, StatusBadge(kind: e.key, label: e.value));
      final StatusColors s = switch (e.key) {
        StatusKind.success => PlutusTokens.light.success,
        StatusKind.warning => PlutusTokens.light.warning,
        StatusKind.info => PlutusTokens.light.info,
        StatusKind.error => PlutusTokens.light.error,
      };
      final Text label = tester.widget<Text>(find.text(e.value));
      expect(label.style!.color, s.text, reason: '${e.key} text');
      final Container pill = tester.widget<Container>(find
          .descendant(
              of: find.byType(StatusBadge), matching: find.byType(Container))
          .first);
      expect((pill.decoration! as BoxDecoration).color, s.surface,
          reason: '${e.key} surface');
    }
  });

  testWidgets('MetricDelta renders exact zero as neutral, no arrow',
      (WidgetTester tester) async {
    await pump(tester, const MetricDelta(percent: 0));
    final Text txt = tester.widget<Text>(find.text('0.0%'));
    expect(txt.style!.color, PlutusTokens.light.textSecondary);
    expect(find.textContaining('▲'), findsNothing);
    expect(find.textContaining('▼'), findsNothing);
  });
```

Add `import 'package:plutus_fe_prototype/theme/plutus_tokens.dart';` if not present (StatusColors is used).

Create `test/widgets/core/entrance_reveal_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/theme/app_theme.dart';
import 'package:plutus_fe_prototype/widgets/core/entrance_reveal.dart';

void main() {
  testWidgets('EntranceReveal fades and settles its child in',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: const Scaffold(
          body: EntranceReveal(index: 0, child: Text('hello'))),
    ));
    final FadeTransition fade = tester.widget<FadeTransition>(find.ancestor(
        of: find.text('hello'), matching: find.byType(FadeTransition)));
    expect(fade.opacity.value, lessThan(1.0));
    await tester.pumpAndSettle();
    expect(fade.opacity.value, 1.0);
  });

  testWidgets('EntranceReveal is instant under disableAnimations',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Scaffold(
            body: EntranceReveal(index: 3, child: Text('now'))),
      ),
    ));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.text('now'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run to verify failures** — status_badge additions fail (`0.0%` not found / arrow rendered); entrance_reveal fails (file missing).

- [ ] **Step 3: Implement MetricDelta zero-delta**

In `lib/widgets/core/metric_delta.dart`, replace the `build` body's color/arrow/text logic with:

```dart
    final PlutusTokens t = context.tokens;
    final String magnitude = '${percent.abs().toStringAsFixed(decimals)}%';
    final bool isZero = percent == 0;
    final bool rising = percent > 0;
    final Color color = isZero
        ? t.textSecondary
        : (rising ? t.success.text : t.error.text);
    final String text =
        isZero ? magnitude : '${rising ? '\u25B2' : '\u25BC'} $magnitude';

    return Text(
      text,
      style: AppTextStyles.numericStyle.copyWith(
        color: color,
        fontSize: AppTextStyles.label,
      ),
    );
```

Update the class doc comment's last line to add: "An exact-zero delta renders as a signless neutral figure."

- [ ] **Step 4: Implement `lib/widgets/core/entrance_reveal.dart`**

```dart
import 'package:flutter/material.dart';
import '../../theme/app_elevation.dart';

/// One orchestrated entrance (spec §8): the child rises 10px and fades in
/// over [AppMotion.slow], delayed 40ms per [index] so sibling blocks
/// cascade header → hero → cards. Skipped entirely under reduced motion.
class EntranceReveal extends StatefulWidget {
  final int index;
  final Widget child;

  const EntranceReveal({super.key, required this.index, required this.child});

  @override
  State<EntranceReveal> createState() => _EntranceRevealState();
}

class _EntranceRevealState extends State<EntranceReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );
  late final CurvedAnimation _curve =
      CurvedAnimation(parent: _controller, curve: AppMotion.emphasized);
  late final Animation<Offset> _offset =
      Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero)
          .animate(_curve);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1.0;
    } else {
      Future<void>.delayed(Duration(milliseconds: 40 * widget.index), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}
```

- [ ] **Step 5: textMuted usage rule (carry-forward)** — in `lib/theme/plutus_tokens.dart`, extend the `textMuted` field's doc comment (or add one) to read:

```dart
  /// Muted text — 3:1 floor, NOT full AA. Use only for non-essential text
  /// (placeholders, timestamps, decorative captions); never for content the
  /// user must read to operate the app.
  final Color textMuted;
```

- [ ] **Step 6: Run tests** — targeted files then full suite. Expected: 603 (599 + 2 badge/delta + 2 reveal).

- [ ] **Step 7: Commit**

```powershell
git add lib/widgets/core/metric_delta.dart lib/widgets/core/entrance_reveal.dart lib/theme/plutus_tokens.dart test/widgets/core/status_badge_test.dart test/widgets/core/entrance_reveal_test.dart
git commit -m "feat(core): EntranceReveal, neutral zero delta, quartet test coverage"
```

---

### Task 3: Navigation bar retokenize

**Files:**
- Modify: `lib/screens/main_navigation_page.dart` (container lines ~51-89, nav item builder, FAB `_buildFab` lines ~157-192)

**Interfaces:**
- Consumes: `context.tokens`, `AppRadius`, `AppTextStyles.labelStyle`. `_DirectionalAxisSwitcher` untouched.
- Produces: spec §5 mobile nav — surface bar, hairline top border, selected item = goldWeak pill behind navy icon + navy label; FAB = gold fill + onGold icon + shadowMedium.

- [ ] **Step 1: Retokenize the bar container** — replace the `BoxDecoration` (currently `AppColors.surfaceElevated` + white@6% dark border + `AppElevation.floatingNav`):

```dart
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: AppRadius.borderSurface,
          border: Border.all(color: t.border),
          boxShadow: t.shadowMedium,
        ),
```

(`final PlutusTokens t = context.tokens;` at the top of the enclosing build; import plutus_tokens.)

- [ ] **Step 2: Retokenize the nav items** — in the per-item builder, the selected state gets a goldWeak pill; icons/labels are navy when selected, muted otherwise. Whatever the current structure (icon + label column with accent color), restyle to:

```dart
    final Color fg = selected ? t.text : t.textSecondary;
    // pill behind the icon when selected:
    Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.componentLg, vertical: AppSpacing.componentXs),
      decoration: BoxDecoration(
        color: selected
            ? (Theme.of(context).brightness == Brightness.dark
                ? Color.alphaBlend(t.goldWeak, t.surface)
                : t.goldWeak)
            : Colors.transparent,
        borderRadius: AppRadius.borderPill,
      ),
      child: Icon(selected ? filledIcon : outlinedIcon, color: fg),
    )
```

with the label `Text(label, style: AppTextStyles.labelStyle.copyWith(color: fg))`. Remove every `AppColors.*` read from the item path.

- [ ] **Step 3: Retokenize the FAB** (`_buildFab`) — replace the `AppGradients.ctaButtonDark`/`AppColors.ctaButtonLight` fill and `AppElevation.fabGlow` with:

```dart
      decoration: BoxDecoration(
        color: t.gold,
        shape: BoxShape.circle,
        boxShadow: t.shadowMedium,
      ),
```

and the icon becomes `Icon(Icons.add_rounded, color: t.onGold)`. Keep the existing onTap/refresh logic byte-identical.

- [ ] **Step 4: Purge imports** — after the edits, `grep -n "AppColors\.\|AppElevation\.\|AppGradients\." lib/screens/main_navigation_page.dart` must return nothing; remove dead imports. `AppMotion` (in app_elevation.dart) may legitimately remain for the switcher — keep that import if `AppMotion` is used.

- [ ] **Step 5: Verify** — `flutter analyze lib` no new issues; `flutter test` all passing (no tests pin this file).

- [ ] **Step 6: Commit**

```powershell
git add lib/screens/main_navigation_page.dart
git commit -m "feat(nav): calm gold/navy bottom bar with goldWeak pill and gold FAB"
```

---

### Task 4: Sidebar menu retokenize

**Files:**
- Modify: `lib/widgets/sidebar_menu.dart` (drawer shell ~55-61, header ~102-177, search ~183-241, tiles ~379-558, footer ~620-705, `_getCategoryColor` ~761-774)

**Interfaces:**
- Consumes: `context.tokens`, `AppTextStyles`, `AppRadius`, `AppSpacing`. `WidgetCatalog`/`WidgetMeta` API untouched.
- Produces: calm drawer — the tile rendering STOPS reading `meta.color` (one-accent policy); `MenuItemData` class is deleted (dead code, zero construction sites — verified).

- [ ] **Step 1: Drawer shell** — replace `Drawer(backgroundColor: transparent, child: GlassContainer(borderRadius: 0, color: ..., opacity: ..., blur: 15, ...))` with:

```dart
    return Drawer(
      backgroundColor: t.surface,
      shape: Border(right: BorderSide(color: t.border)),
      child: /* existing column */
    );
```

- [ ] **Step 2: Header** — the gradient banner becomes a flat navy block, fixed in both themes (same pattern as HeroCard): background `t.heroSurface`; greeting/title text `AppTextStyles.titleStyle.copyWith(color: const Color(0xFFEDF0F7))` (fixed light ink on fixed navy — gold is reserved for figures, so do NOT use `t.heroText` here); the small eyebrow label, if present, `AppTextStyles.overlineStyle.copyWith(color: t.heroLabel)`; the app-icon chip gets a `t.heroBorder` hairline circle. Remove the gradient entirely.

- [ ] **Step 3: Search bar** — replace the white/black literals with a themed field: fill `t.surfaceSubtle`, hairline `t.borderStrong`, radius `AppRadius.input`, hint `t.textMuted`, text `t.text`, icon `t.textSecondary`. (Plain `TextField` with an explicit `InputDecoration` matching the global input theme.)

- [ ] **Step 4: Category headers + tiles** — delete `_getCategoryColor`; category header icon+label render `t.textSecondary` with `AppTextStyles.overlineStyle` (uppercase at call-site). Tiles: leading icon chip = `t.surfaceSubtle` circle with `t.brandNavy` icon (was `meta.color`); label `t.text`; count badge = `t.goldWeak` fill + `t.goldText` text; "Add" affordance = gold: `Icon(Icons.add_circle_outline, color: t.goldText)`; visibility `Switch.adaptive` inherits the global gold switch theme (drop per-tile color overrides); remove buttons `t.error.text`. Dividers `t.border` (replace `Colors.white12`/`white24`/`black12`).

- [ ] **Step 5: Footer** — hairline top border `t.border`; count text `t.textMuted`; Settings row icon+label `t.textSecondary`/`t.text`; sign-out `t.error.text` (destructive), sign-in `t.goldText`.

- [ ] **Step 6: Delete `MenuItemData`** (lines ~778-790) — zero construction sites repo-wide (verified in survey). If `grep -rn "MenuItemData" lib/ test/` shows any OTHER reference, keep the class and note it in the report instead.

- [ ] **Step 7: Purge + verify** — `grep -n "AppColors\.\|GlassContainer\|Colors.white\|Colors.black" lib/widgets/sidebar_menu.dart` → only `Colors.transparent` and the fixed-navy header ink may remain; remove dead imports. `flutter analyze lib` + `flutter test`.

- [ ] **Step 8: Commit**

```powershell
git add lib/widgets/sidebar_menu.dart
git commit -m "feat(nav): calm token-driven sidebar, one-accent tiles, drop dead MenuItemData"
```

---

### Task 5: Dashboard screen chrome

**Files:**
- Modify: `lib/screens/dashboard_screen.dart` (slot background builder ~464-499, ItemStyle ~573-580, appbar/picker/menus ~255-381, alerts banner ~171-211, edit-mode entry icon, `_buildWidgetPreview` ~876-877; DELETE dead `MySlotBackground` class ~39-59)

**Interfaces:**
- Consumes: `context.tokens`, `EntranceReveal` (Task 2), `AppRadius.card`.
- Produces: token-driven dashboard shell; `MySlotBackground` gone; staggered entrance on banner + grid.

- [ ] **Step 1: Delete `MySlotBackground`** (dead code — zero instantiation sites, survey-verified; re-verify with `grep -rn "MySlotBackground" lib/ test/` first; if any live reference exists, stop and report instead of deleting).

- [ ] **Step 2: Slot background builder** — in the inline `SlotBackgroundBuilder.withFunction`, replace `AppColors.borderLine(brightness)` idle outline with `t.border`, `AppColors.editSnapGlow(b)` with `t.gold.withValues(alpha: isDark ? 0.22 : 0.16)`, `AppColors.editOutline(b)` with `t.gold.withValues(alpha: isDark ? 0.55 : 0.45)`.

- [ ] **Step 3: ItemStyle** — `RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card))` (was `AppRadius.lg`), `elevation: 0` (cards carry their own AppCard shadow now), `color: Colors.transparent` stays.

- [ ] **Step 4: AppBar + menus** — dashboard picker & "more" menu: `AppColors.textPrimary/Secondary/Tertiary` → `t.text`/`t.textSecondary`/`t.textMuted`; checkmark/add icons `AppColors.brand(b)` → `t.goldText`; destructive rows `AppColors.error` → `t.error.text`; edit toggle icon `AppColors.editAccent` → `t.goldText`. Popup menus inherit themed surfaces — drop explicit colors where the theme now covers them.

- [ ] **Step 5: Alerts banner** — restyle to the warning quartet: container `t.warning.surface` fill + `Border.all(color: t.warning.border)` + text/icon `t.warning.text` (replaces `AppColors.warning` @15% alpha improvisation).

- [ ] **Step 6: `_buildWidgetPreview` + placeholder slots** — debug preview `AppColors.primary` → `t.brandNavy`; the `item.data == null` placeholder `GlassContainer(color: item.color, opacity: 0.3)` → `AppCard(child: ...)` (item.color is always null — plain calm card).

- [ ] **Step 7: Staggered entrance** — wrap the alerts banner in `EntranceReveal(index: 0, ...)` and the `Dashboard<ColoredDashboardItem>` grid in `EntranceReveal(index: 1, ...)` (spec §8: header → content cascade; the hero inside net-worth widget animates with the grid).

- [ ] **Step 8: Purge + verify** — `grep -n "AppColors\.\|GlassContainer" lib/screens/dashboard_screen.dart` → nothing; dead imports removed; `flutter analyze lib` + `flutter test` (test/widgets/dashboard_edit_mode_test.dart mirrors logic, doesn't pin colors — must still pass).

- [ ] **Step 9: Commit**

```powershell
git add lib/screens/dashboard_screen.dart
git commit -m "feat(dashboard): token-driven shell, gold edit glow, staggered entrance"
```

---

### Task 6: Edit-mode chrome + dashboard package restyle

**Files:**
- Modify: `lib/widgets/dashboard/edit_mode_banner.dart`, `lib/widgets/dashboard/empty_slot_tile.dart`, `lib/widgets/dashboard/widget_edit_chrome.dart`, `lib/screens/dashboard_screen.dart:590-596` (EditModeBackgroundStyle args)
- Modify: `packages/dashboard/lib/src/edit_mode/edit_mode_settings.dart` (add optional param), `packages/dashboard/lib/src/widgets/dashboard_item_widget.dart:217,222` (consume it)

**Interfaces:**
- Consumes: `context.tokens`, `StatusBadge` quartet colors.
- Produces: spec §7 — edit banner as navy `info` bar; handles/snap glow gold low-alpha; empty slots dashed hairline + gold add affordance; NEW `EditModeSettings.swapHighlightColor` (`Color?`, defaults to the package's previous `Color(0xFF4CAF50)` so the package is standalone-compatible), consumed by `dashboard_item_widget.dart` in place of both hardcoded greens; the app passes `swapHighlightColor: t.gold`.
- `WidgetEditAction` enum and its dispatch semantics are PINNED by test/widgets/dashboard_edit_mode_test.dart — do not rename/reorder.

- [ ] **Step 1: Package param** — in `edit_mode_settings.dart` add `final Color swapHighlightColor;` with constructor param `this.swapHighlightColor = const Color(0xFF4CAF50),` (doc: "Highlight for the item a drag would swap with."). In `dashboard_item_widget.dart` lines 217/222 replace both `const Color(0xFF4CAF50)` literals with the settings read (the widget already has access to the `EditModeSettings` instance — follow how `backgroundStyle` is accessed in the same file).

- [ ] **Step 2: App passes the new style** — in dashboard_screen.dart's `EditModeSettings(...)` call: `lineColor: t.border`, `fillColor: t.gold.withValues(alpha: 0.08)` (was silently `Colors.black38`), `swapHighlightColor: t.gold`.

- [ ] **Step 3: `edit_mode_banner.dart`** — restyle to the info quartet: container `t.info.surface` + `Border.all(color: t.info.border)`, icon/title `t.info.text`, buttons `t.goldText` (Done) / `t.textSecondary` (Undo). Remove `AppElevation.brandGlow` (banner sits flush — `t.shadowLow` if any shadow).

- [ ] **Step 4: `empty_slot_tile.dart`** — dashed `_DashedRectPainter` stroke `t.border`; center icon `t.textMuted`; the add affordance (icon or plus chip) `t.goldText`; hover/pressed wash `t.goldWeak`.

- [ ] **Step 5: `widget_edit_chrome.dart`** — outline `t.gold.withValues(alpha: 0.45)` (was editOutline), handle chips `t.gold` fill + `t.onGold` glyphs (fixes the parked white-on-gold contrast item), action icons `t.text`, destructive remove `t.error.text`.

- [ ] **Step 6: Purge + verify** — `grep -n "AppColors\.\|AppElevation\." lib/widgets/dashboard/` → nothing. `flutter analyze` (INCLUDING packages/dashboard — no new issues there) + `flutter test` (dashboard_edit_mode_test must pass untouched).

- [ ] **Step 7: Commit**

```powershell
git add lib/widgets/dashboard/edit_mode_banner.dart lib/widgets/dashboard/empty_slot_tile.dart lib/widgets/dashboard/widget_edit_chrome.dart lib/screens/dashboard_screen.dart packages/dashboard/lib/src/edit_mode/edit_mode_settings.dart packages/dashboard/lib/src/widgets/dashboard_item_widget.dart
git commit -m "feat(dashboard): gold edit chrome and parameterized swap highlight"
```

---

### Task 7: Widget migration A — net worth hero (flagship)

**Files:**
- Modify: `lib/widgets/net_worth_trend_widget.dart` (outer card ~:55, summary block ~288-308)

**Interfaces:**
- Consumes: `HeroCard` (PR1), recipe, `PlutusChartStyle.formatCompactCurrency`, existing l10n net-worth key (reuse the key the current `Text('Net Worth:')` uses; if it is a raw literal, add `net_worth` EN "Net worth" / VI "Tài sản ròng" + getter per the l10n recipe).
- Produces: the app's signature moment — spec §7: hero net-worth card in navy + gold serif; chart below in a calm card.

- [ ] **Step 1: Restructure the widget's build** — the widget's root becomes a `Column`:
  1. `HeroCard(label: <l10n net worth string>, value: '${currency.symbol}${PlutusChartStyle.formatCompactCurrency(_currentNetWorth)}')` — delete the old `GlassContainer` summary Row (lines ~288-308) including its positive/negative coloring (the hero figure is ALWAYS gold serif per spec §3.4; directional signal returns in a later iteration as a MetricDelta footer when period-delta data exists — do NOT invent a delta computation now, YAGNI).
  2. `const SizedBox(height: AppSpacing.componentMd)`,
  3. `Expanded(child: AppCard(child: <existing LineChart block>))` — apply the recipe to the chart block (line color `t.chartCategorical.first`, grid via PlutusChartStyle, axis labels `t.textMuted`).

- [ ] **Step 2: Apply the recipe** to everything else in the file (outer GlassContainer removed in favor of the Column above — the widget fills its grid slot directly; header row title `t.text`, icons `t.textMuted`).

- [ ] **Step 3: Verify** — recipe grep clean for this file; `flutter analyze lib`; `flutter test`.

- [ ] **Step 4: Commit**

```powershell
git add lib/widgets/net_worth_trend_widget.dart lib/l10n/app_localizations.dart
git commit -m "feat(widgets): net-worth HeroCard hero with calm trend chart"
```

(Omit the l10n file from staging if no new key was needed.)

---

### Task 8: Widget migration B — budget pair

**Files:** `lib/widgets/budget_summary_widget.dart`, `lib/widgets/category_budget_widget.dart`

Apply the recipe to both. File-specific notes:
- budget_summary: 3 GlassContainers (one accent outer + inner chips) → 1 `AppCard` outer + `t.surfaceSubtle` chips. Budget progress bars: track `t.surfaceSubtle`, healthy fill `t.success.dot`, warning `t.warning.dot`, over-budget `t.error.dot`. The gold "Create Budget" CTA comes from the themed `FilledButton` — remove any explicit fill.
- category_budget: same treatment; per-category rows are hairline-separated (`t.border`) list rows, amounts right-aligned in `AppTextStyles.numericStyle.copyWith(color: t.text)`.

- [ ] **Step 1: Migrate both files per recipe** (+ notes above)
- [ ] **Step 2: Recipe grep clean; `flutter analyze lib`; `flutter test`**
- [ ] **Step 3: Commit** — `git add lib/widgets/budget_summary_widget.dart lib/widgets/category_budget_widget.dart && git commit -m "feat(widgets): calm budget cards on tokens"`

---

### Task 9: Widget migration C — trends (cashflow, income, savings)

**Files:** `lib/widgets/cashflow_widget.dart`, `lib/widgets/income_trend_widget.dart`, `lib/widgets/savings_rate_widget.dart`

Apply the recipe. File-specific notes:
- cashflow (938 LOC, raw fl_chart): income series `t.chartCategorical.first` (navy), expense series `t.chartCategorical[3]` (teal) — NOT red/green fills for bars (calm); net line `t.chartCategorical[1]` (gold) if a net overlay exists. Positive/negative TEXT deltas keep `t.success.text`/`t.error.text`.
- income_trend: the accent-drift gotcha (used historyAccent) is mooted — accent removed by recipe. Line `t.chartCategorical.first`.
- savings_rate (custom gauge): gauge track `t.surfaceSubtle`, fill `t.gold` (a key financial figure — the one gold moment of this card), rate text `t.text` numeric, target markers `t.textMuted`, warning state `t.warning.text`.

- [ ] **Step 1: Migrate all three per recipe** (+ notes)
- [ ] **Step 2: Recipe grep clean; `flutter analyze lib`; `flutter test`** (income_trend_logic_test.dart + savings_rate_gauge_test.dart exist — they test logic, not colors; they must stay green unmodified. If either pins a color, update the expectation and record it.)
- [ ] **Step 3: Commit** — `git add lib/widgets/cashflow_widget.dart lib/widgets/income_trend_widget.dart lib/widgets/savings_rate_widget.dart && git commit -m "feat(widgets): calm trend cards on tokens"`

---

### Task 10: Widget migration D — breakdown charts (expense, heatmap, market)

**Files:** `lib/widgets/expense_breakdown_chart_widget.dart`, `lib/widgets/spending_heatmap_widget.dart`, `lib/widgets/market_trending_widget.dart`

Apply the recipe. File-specific notes:
- expense_breakdown: pie/bar slices `t.chartCategorical[i % 6]`; legend text `t.textSecondary`; drop `PlutusChartColors` import.
- spending_heatmap: replace the hardcoded ramp (`0xFF111827`, `0xFF1E2D3D`, `0xFFE74C3C`) with `t.heatmapRamp` — bucket intensity 0..4 → `t.heatmapRamp[bucket]`; cell borders `t.border`; day labels `t.textMuted`. This is exactly what the token was built for (PR1 carry-forward).
- market_trending: sparklines `t.chartCategorical.first`; gains/losses text `t.success.text`/`t.error.text`; drop `PlutusChartColors`.

- [ ] **Step 1: Migrate all three per recipe** (+ notes)
- [ ] **Step 2: Recipe grep clean (also `grep -n "0xFF111827\|0xFF1E2D3D\|0xFFE74C3C" lib/widgets/spending_heatmap_widget.dart` → nothing); `flutter analyze lib`; `flutter test`** (spending_heatmap_logic_test.dart tests logic — keep green.)
- [ ] **Step 3: Commit** — `git add lib/widgets/expense_breakdown_chart_widget.dart lib/widgets/spending_heatmap_widget.dart lib/widgets/market_trending_widget.dart && git commit -m "feat(widgets): tokenized breakdown charts and gold heatmap ramp"`

---

### Task 11: Widget migration E — bills + tax

**Files:** `lib/widgets/upcoming_bills_widget.dart`, `lib/widgets/tax_estimation_widget.dart`

Apply the recipe. File-specific notes:
- upcoming_bills (1003 LOC, 3 GlassContainers): bill status chips → `StatusBadge` (import `../core/status_badge.dart`): paid=success, due-soon=warning, overdue=error; the `0xFF6050dc` literal → `t.chartCategorical[4]` (plum) if a series color, else `t.brandNavy`; timeline chart per recipe.
- tax_estimation (837 LOC, 7 GlassContainers): one outer `AppCard`, all six inner chips → `t.surfaceSubtle` containers; bracket highlight `t.goldWeak` + `t.goldText` (active bracket = the gold moment); estimated tax figure `AppTextStyles.numericStyle` + `t.text`.

- [ ] **Step 1: Migrate both per recipe** (+ notes)
- [ ] **Step 2: Recipe grep clean; `flutter analyze lib`; `flutter test`**
- [ ] **Step 3: Commit** — `git add lib/widgets/upcoming_bills_widget.dart lib/widgets/tax_estimation_widget.dart && git commit -m "feat(widgets): calm bills and tax cards with status badges"`

---

### Task 12: Widget migration F — investments (investment, irr, roi, portfolio)

**Files:** `lib/widgets/investment_widget.dart`, `lib/widgets/irr_widget.dart`, `lib/widgets/roi_widget.dart`, `lib/widgets/portfolio_allocation_widget.dart`

Apply the recipe. File-specific notes:
- investment (1324 LOC, 4 GlassContainers incl. legacy blur params — blur is a no-op, drop silently): outer `AppCard`; holdings rows hairline-separated; per-holding gain/loss → `MetricDelta(percent: ...)` (import `../core/metric_delta.dart`) replacing hand-rolled arrow+color text where the data is a percentage; portfolio total figure `t.goldText` numeric (spec §7: portfolio total in gold numeric — the card's one gold moment).
- irr + roi (176 LOC each, near-twins): single `AppCard`, metric figure `AppTextStyles.numericStyle` + `t.text`, positive/negative sub-text `t.success.text`/`t.error.text`; do NOT merge the two files (out of scope).
- portfolio_allocation: pie slices `t.chartCategorical[i % 6]`; `0xFF95A5A6` literal → `t.chartCategorical[5]` (the grey slot); legend `t.textSecondary`; drop `PlutusChartColors`.

- [ ] **Step 1: Migrate all four per recipe** (+ notes)
- [ ] **Step 2: Recipe grep clean; `flutter analyze lib`; `flutter test`**
- [ ] **Step 3: Commit** — `git add lib/widgets/investment_widget.dart lib/widgets/irr_widget.dart lib/widgets/roi_widget.dart lib/widgets/portfolio_allocation_widget.dart && git commit -m "feat(widgets): calm investment cards, gold portfolio total, MetricDelta rows"`

---

### Task 13: Widget migration G — history, profile, dispatch cleanup

**Files:** `lib/widgets/transaction_history_widget.dart`, `lib/widgets/profile_dashboard_widget.dart`, `lib/widgets/profile_widget.dart`, `lib/widgets/data_widget.dart`

Apply the recipe. File-specific notes:
- transaction_history: rows dense hairline list; amounts right-aligned numeric `t.text`; +/− amounts `t.success.text`/`t.error.text`; the selected-row container uses the recipe's goldWeak selected variant; `0xFF34A853` literal → `t.success.dot`.
- profile_dashboard + profile (971 LOC): outer `AppCard`; avatar ring `t.border` (gold ring is the SELECTED state on user-selection screen — PR3, not here); name label `AppTextStyles.overlineStyle` + `t.textMuted` (call-site uppercases); menuBackground/borderDark reads → `t.surface`/`t.border`; edit/camera affordances `t.textSecondary`.
- data_widget: delete the unused module-level `blue/red/yellow/green` color aliases (lines ~28-31); dispatch map untouched.

- [ ] **Step 1: Migrate all four per recipe** (+ notes)
- [ ] **Step 2: Full-surface purge check** — `grep -rn "GlassContainer" lib/widgets/ lib/screens/ --include="*.dart" | grep -v "glass_container.dart"` → ONLY files outside PR2 scope (import tabs, insights, report widgets, dialogs — those are PR3). Record the remaining list in the report for PR3 planning.
- [ ] **Step 3: `flutter analyze lib`; `flutter test`** (avatar_editor_widget_test.dart exists — logic-level, keep green.)
- [ ] **Step 4: Commit** — `git add lib/widgets/transaction_history_widget.dart lib/widgets/profile_dashboard_widget.dart lib/widgets/profile_widget.dart lib/widgets/data_widget.dart && git commit -m "feat(widgets): calm history and profile cards, drop dead color aliases"`

---

### Task 14: Verification sweep

**Files:** none (verification only)

- [ ] **Step 1:** `flutter analyze` → no issues beyond the 73-issue baseline (packages/dashboard/example).
- [ ] **Step 2:** `flutter test` → all green (expected 603+).
- [ ] **Step 3:** `flutter build web --release --no-tree-shake-icons --source-maps --dart-define=FLUTTER_WEB_AUTO_DETECT=true --dart-define-from-file=app.env` → succeeds.
- [ ] **Step 4: Visual smoke** (controller-run, `flutter run -d web-server --web-port 8321 --dart-define-from-file=app.env`, Playwright at 1280px + 390px, light + dark):
  - Canvas: faint gold wash (subtle — the heavy legacy wash must be GONE).
  - Dashboard: HeroCard renders navy with GOLD SERIF figure (Cormorant — visually confirm the serif weight, PR1 carry-forward); widgets are calm white/navy cards, no pastel accent tints anywhere; max one gold moment per card.
  - Nav: goldWeak pill + navy icon on the active item; gold FAB with navy plus.
  - Edit mode: gold outline/handles/snap glow; drag-over-swap shows GOLD highlight (not green); banner reads as info quartet.
  - Sidebar: calm drawer, navy header, gold count badges.
  - Theme toggle (Settings → theme): canvas and hero crossfade smoothly — no snap (AnimatedThemeScope lerp path).
  - No regression on unmigrated screens (History tab, import page render acceptably on shims).
- [ ] **Step 5:** Fix anything broken; re-run affected tests; commit fixes with `fix(...)` messages.

---

### Task 15: Push + open PR

- [ ] **Step 1:** `git push -u origin feat/nav-dashboard-redesign`
- [ ] **Step 2:** `gh pr create --base main` — title `feat(nav,dashboard): calm gold/navy core experience (redesign PR2)`; body follows the repo convention (Summary bullets / Verification evidence / Next: PR3 screens), listing: AppCanvas wiring, nav + FAB, sidebar, dashboard shell + edit chrome (incl. package swap-highlight param), all 19 widgets on tokens, HeroCard hero, EntranceReveal, carry-forward closures.
- [ ] **Step 3:** Report the PR URL.

---

## Plan self-review record

- **Spec coverage (PR2 = spec §7 rows 3-4 + §10 row 2 + §8 entrance + PR1 carry-forwards):** canvas (T1), motion entrance (T2/T5), nav (T3), sidebar (T4), dashboard shell (T5), edit chrome + package (T6), hero (T7), all 19 widgets (T7-T13), heatmap ramp consumption (T10), portfolio gold total (T12), verification + PR (T14-15). Carry-forwards: AppCanvas test (T1), textMuted rule (T2), MetricDelta zero (T2), StatusBadge arms (T2), theme-toggle visual check (T14), swap-highlight green (T6), white-on-gold edit handles (T6). Deliberately out of scope (PR3): history/import/insights/investment screens, report widgets, dialogs, login/user-selection; (PR4): shim deletion, GlassContainer/GlassBackground removal, web shell.
- **Placeholder scan:** recipe + per-file notes carry exact identifier mappings; no TBDs. Two survey-verified deletions (MySlotBackground, MenuItemData) carry re-verify-then-delete guards.
- **Type consistency:** `EntranceReveal(index:, child:)` (T2) matches T5 usage; `EditModeSettings.swapHighlightColor` (T6) named consistently; recipe token names match PlutusTokens fields shipped in PR1.
- **Known judgment calls (documented):** hero figure always gold (no pos/neg coloring, no invented delta); nav keeps the floating-container structure (retokenized) rather than converting to Material NavigationBar; sidebar header uses fixed-navy ink like HeroCard; `PlutusChartColors` left as deprecated shim for PR3 stragglers (import tabs/report widgets) and dies in PR4.
