# Gold/Navy Redesign — PR1: Token Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the `PlutusTokens` ThemeExtension, revalued gold/navy design tokens, bundled fonts, rebuilt ThemeData component themes, and the core widget primitives — so the entire app re-tints gold/navy through the legacy shims while later PRs migrate call-sites.

**Architecture:** Approach B from the spec (`docs/superpowers/specs/2026-07-29-gold-navy-redesign-design.md`): everything brightness-dependent lives in a new `ThemeExtension<PlutusTokens>` accessed via `context.tokens`; compile-time scales (`AppSpacing`, `AppRadius`, `AppMotion`, type sizes) stay `const`. Legacy statics (`AppColors`, `AppElevation`, `AppGradients`) are revalued to the new palette and `@Deprecated` so unmigrated widgets instantly render gold/navy. New primitives (`AppCanvas`, `AppCard`, `HeroCard`, `StatusBadge`, `MetricDelta`, `MeanderDivider`, `EmptyState`, `AppSkeleton`) land under `lib/widgets/core/` for PR2/3 to consume.

**Tech Stack:** Flutter (Dart SDK ^3.11.0), Material 3, package name `plutus_fe_prototype`, `flutter_test`, bundled TTF fonts (Inter, Cormorant Garamond). No new pub dependencies.

## Global Constraints

- Visual layer only: no changes to routes, providers, services, models, or business logic.
- Do NOT touch `Plutus-backend-prototype-2/`, `lambda/`, `terraform/`, or `packages/dashboard/` (dashboard package is PR2).
- No new pub dependencies; fonts ship as bundled assets (no runtime fetch). Leave the existing unused `google_fonts` dependency alone (removal is PR4 cleanup).
- Raw `gold` is never used as text on light surfaces — only `goldText` / `onGold` pairings (spec §3.6).
- `const` constructors wherever possible; explicit types; no `dynamic`.
- New primitives take all user-facing strings from callers — no hardcoded copy inside `lib/widgets/core/`.
- Verification gates (every task's commit point): `flutter analyze` shows no NEW errors (pre-existing errors in `packages/dashboard/example` are baseline; deprecation infos are expected and suppressed per Task 6), `flutter test` green.
- Working directory: `D:\Backup\Work\Uni\COS40005\Plutus\Plutus-FE-prototype-1`. Shell is PowerShell — use PowerShell syntax for downloads, `git` commands work as normal.
- If `app.env` is missing (fresh checkout), create it before running tests: `if (-not (Test-Path app.env)) { New-Item -ItemType File app.env }`.
- Canonical web build command (from `amplify.yml:33`): `flutter build web --release --no-tree-shake-icons --source-maps --dart-define=FLUTTER_WEB_AUTO_DETECT=true --dart-define-from-file=app.env` (CLAUDE.md's `--no-wasm` variant is stale — do not use it).
- Conventional commits. All work on branch `feat/gold-navy-tokens`, PR to `main`.
- Do not commit the user's pre-existing modified `.gitignore` — stage files explicitly by path, never `git add -A`.

## Reference: the palette (spec §3)

Navy ramp: 50 `#F4F6FB` 100 `#E9EDF6` 200 `#D6DDED` 300 `#B3BFDB` 400 `#8093BC` 500 `#52659A` 600 `#33457D` 700 `#24346A` 800 `#1A2650` 900 `#131C3D` 950 `#0C122A`
Gold ramp: 50 `#FDF9EC` 100 `#FAF0CE` 200 `#F4E09A` 300 `#ECCB5F` 400 `#E0B32F` 500 `#C9970F` 600 `#A67A0B` 700 `#85610D` 800 `#664A0E` 900 `#4A350B`

One deliberate nudge from the spec: light `textMuted` is `#7E88A3` (not the spec's `#8A93AB`, which measures 2.78:1 on `surfaceSubtle` — below the 3.0 floor). Spec §3.4 allows nudging values, never the rule.

---

### Task 1: Branch + bundled fonts

**Files:**
- Create: `lib/assets/fonts/Inter-Regular.ttf`, `Inter-Medium.ttf`, `Inter-SemiBold.ttf`, `Inter-Bold.ttf`, `CormorantGaramond-SemiBold.ttf` (binary downloads)
- Modify: `pubspec.yaml` (fonts section, currently commented out at lines ~140-155)

**Interfaces:**
- Produces: font family `'Inter'` (weights 400/500/600/700) and `'CormorantGaramond'` (weight 600) resolvable by `TextStyle.fontFamily`. `lib/theme/app_text_styles.dart:50` already declares `fontFamily = 'Inter'`, so bundling activates it app-wide with zero code change.

- [ ] **Step 1: Create branch**

```powershell
git checkout -b feat/gold-navy-tokens
```

- [ ] **Step 2: Download Inter static TTFs**

```powershell
New-Item -ItemType Directory -Force lib/assets/fonts
Invoke-WebRequest -Uri "https://github.com/rsms/inter/releases/download/v4.1/Inter-4.1.zip" -OutFile "$env:TEMP\inter.zip"
Expand-Archive "$env:TEMP\inter.zip" "$env:TEMP\inter" -Force
Get-ChildItem "$env:TEMP\inter" -Recurse -Include Inter-Regular.ttf,Inter-Medium.ttf,Inter-SemiBold.ttf,Inter-Bold.ttf | Copy-Item -Destination lib/assets/fonts/
Get-ChildItem lib/assets/fonts
```

Expected: the four `Inter-*.ttf` files listed. (The zip nests statics under `extras/ttf/` — the recursive search finds them regardless of layout.)

- [ ] **Step 3: Download Cormorant Garamond 600**

Try the static file first; if it 404s (family may have gone variable-only in google/fonts), fall back to the variable font under the same target filename — the `heroSerif` style in Task 8 sets `FontVariation('wght', 600)` which is honored by variable fonts and harmlessly ignored by statics, so both paths work:

```powershell
try {
  Invoke-WebRequest -Uri "https://raw.githubusercontent.com/google/fonts/main/ofl/cormorantgaramond/CormorantGaramond-SemiBold.ttf" -OutFile "lib/assets/fonts/CormorantGaramond-SemiBold.ttf" -ErrorAction Stop
} catch {
  Invoke-WebRequest -Uri "https://raw.githubusercontent.com/google/fonts/main/ofl/cormorantgaramond/CormorantGaramond%5Bwght%5D.ttf" -OutFile "lib/assets/fonts/CormorantGaramond-SemiBold.ttf"
}
```

- [ ] **Step 4: Declare fonts in pubspec.yaml**

Replace the commented-out `# fonts:` example block (inside the `flutter:` section) with:

```yaml
  fonts:
    - family: Inter
      fonts:
        - asset: lib/assets/fonts/Inter-Regular.ttf
          weight: 400
        - asset: lib/assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: lib/assets/fonts/Inter-SemiBold.ttf
          weight: 600
        - asset: lib/assets/fonts/Inter-Bold.ttf
          weight: 700
    - family: CormorantGaramond
      fonts:
        - asset: lib/assets/fonts/CormorantGaramond-SemiBold.ttf
          weight: 600
```

- [ ] **Step 5: Verify**

```powershell
flutter pub get; flutter test
```

Expected: pub get resolves, all existing tests pass.

- [ ] **Step 6: Commit**

```powershell
git add lib/assets/fonts pubspec.yaml
git commit -m "feat(theme): bundle Inter and Cormorant Garamond font assets"
```

---

### Task 2: `PlutusTokens` ThemeExtension

**Files:**
- Create: `lib/theme/plutus_tokens.dart`
- Test: `test/theme/plutus_tokens_test.dart`

**Interfaces:**
- Produces (consumed by every later task and PR):
  - `class StatusColors { Color text; Color surface; Color border; Color dot; }` with `static StatusColors lerp(StatusColors a, StatusColors b, double t)`
  - `class PlutusTokens extends ThemeExtension<PlutusTokens>` with fields: `bg, surface, surfaceSubtle, border, borderStrong, text, textSecondary, textMuted, brandNavy, gold, goldHover, goldWeak, goldText, onGold` (all `Color`); `success, warning, info, error` (all `StatusColors`); `chartCategorical, heatmapRamp` (`List<Color>`); `shadowLow, shadowMedium, shadowHigh` (`List<BoxShadow>`); `heroSurface, heroBorder, heroText, heroLabel` (`Color`)
  - `static const PlutusTokens light` / `static const PlutusTokens dark`
  - `extension PlutusTokensX on BuildContext { PlutusTokens get tokens; }`

- [ ] **Step 1: Write the failing test**

Create `test/theme/plutus_tokens_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/theme/plutus_tokens.dart';

void main() {
  group('PlutusTokens', () {
    test('light and dark expose the full gold/navy token set', () {
      expect(PlutusTokens.light.bg, const Color(0xFFF7F8FA));
      expect(PlutusTokens.light.gold, const Color(0xFFC9970F));
      expect(PlutusTokens.light.text, const Color(0xFF131C3D));
      expect(PlutusTokens.dark.bg, const Color(0xFF0C1120));
      expect(PlutusTokens.dark.gold, const Color(0xFFE0B32F));
      expect(PlutusTokens.light.chartCategorical, hasLength(6));
      expect(PlutusTokens.dark.chartCategorical, hasLength(6));
      expect(PlutusTokens.light.heatmapRamp, hasLength(5));
      expect(PlutusTokens.light.success.dot, const Color(0xFF079455));
      expect(PlutusTokens.light.shadowLow, isNotEmpty);
    });

    test('lerp at t=0 and t=1 returns endpoint values', () {
      final PlutusTokens at0 = PlutusTokens.light.lerp(PlutusTokens.dark, 0.0);
      final PlutusTokens at1 = PlutusTokens.light.lerp(PlutusTokens.dark, 1.0);
      expect(at0.bg, PlutusTokens.light.bg);
      expect(at0.success.text, PlutusTokens.light.success.text);
      expect(at1.bg, PlutusTokens.dark.bg);
      expect(at1.goldWeak, PlutusTokens.dark.goldWeak);
    });

    test('lerp midpoint blends between light and dark', () {
      final PlutusTokens mid = PlutusTokens.light.lerp(PlutusTokens.dark, 0.5);
      expect(mid.bg, Color.lerp(PlutusTokens.light.bg, PlutusTokens.dark.bg, 0.5));
      expect(mid.gold, Color.lerp(PlutusTokens.light.gold, PlutusTokens.dark.gold, 0.5));
    });

    test('copyWith overrides a single field and keeps the rest', () {
      final PlutusTokens t = PlutusTokens.light.copyWith(gold: const Color(0xFF000000));
      expect(t.gold, const Color(0xFF000000));
      expect(t.bg, PlutusTokens.light.bg);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/theme/plutus_tokens_test.dart`
Expected: FAIL — `Error: Couldn't resolve the package 'plutus_fe_prototype/theme/plutus_tokens.dart'` (file does not exist).

- [ ] **Step 3: Implement `lib/theme/plutus_tokens.dart`**

```dart
import 'package:flutter/material.dart';

/// Status color quartet (spec §3.4). Status is always expressed as this
/// coordinated set — never an ad-hoc red or green.
@immutable
class StatusColors {
  final Color text;
  final Color surface;
  final Color border;
  final Color dot;

  const StatusColors({
    required this.text,
    required this.surface,
    required this.border,
    required this.dot,
  });

  static StatusColors lerp(StatusColors a, StatusColors b, double t) {
    return StatusColors(
      text: Color.lerp(a.text, b.text, t)!,
      surface: Color.lerp(a.surface, b.surface, t)!,
      border: Color.lerp(a.border, b.border, t)!,
      dot: Color.lerp(a.dot, b.dot, t)!,
    );
  }
}

/// Brightness-dependent design tokens for the gold/navy design language.
/// Compile-time scales (spacing, radius, motion, type sizes) stay in their
/// static classes; everything here varies between light and dark.
@immutable
class PlutusTokens extends ThemeExtension<PlutusTokens> {
  // ── Canvas & surfaces ──
  final Color bg;
  final Color surface;
  final Color surfaceSubtle;
  final Color border;
  final Color borderStrong;

  // ── Text ──
  final Color text;
  final Color textSecondary;
  final Color textMuted;

  // ── Brand ──
  final Color brandNavy;
  final Color gold;
  final Color goldHover;
  final Color goldWeak;

  /// The only gold ever used as text on this theme's surfaces.
  final Color goldText;

  /// Foreground on gold fills (the signature gold-CTA/navy-label pairing).
  final Color onGold;

  // ── Status quartets ──
  final StatusColors success;
  final StatusColors warning;
  final StatusColors info;
  final StatusColors error;

  // ── Charts ──
  final List<Color> chartCategorical;
  final List<Color> heatmapRamp;

  // ── Elevation ──
  final List<BoxShadow> shadowLow;
  final List<BoxShadow> shadowMedium;
  final List<BoxShadow> shadowHigh;

  // ── Hero card ──
  final Color heroSurface;
  final Color heroBorder;
  final Color heroText;
  final Color heroLabel;

  const PlutusTokens({
    required this.bg,
    required this.surface,
    required this.surfaceSubtle,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.textSecondary,
    required this.textMuted,
    required this.brandNavy,
    required this.gold,
    required this.goldHover,
    required this.goldWeak,
    required this.goldText,
    required this.onGold,
    required this.success,
    required this.warning,
    required this.info,
    required this.error,
    required this.chartCategorical,
    required this.heatmapRamp,
    required this.shadowLow,
    required this.shadowMedium,
    required this.shadowHigh,
    required this.heroSurface,
    required this.heroBorder,
    required this.heroText,
    required this.heroLabel,
  });

  static const PlutusTokens light = PlutusTokens(
    bg: Color(0xFFF7F8FA),
    surface: Color(0xFFFFFFFF),
    surfaceSubtle: Color(0xFFF1F3F6),
    border: Color(0xFFE5E8EE),
    borderStrong: Color(0xFFCDD3DE),
    text: Color(0xFF131C3D),
    textSecondary: Color(0xFF4A5573),
    textMuted: Color(0xFF7E88A3),
    brandNavy: Color(0xFF24346A),
    gold: Color(0xFFC9970F),
    goldHover: Color(0xFFA67A0B),
    goldWeak: Color(0xFFFDF9EC),
    goldText: Color(0xFF85610D),
    onGold: Color(0xFF0C122A),
    success: StatusColors(
      text: Color(0xFF067647),
      surface: Color(0xFFECFDF3),
      border: Color(0xFFA6F4C5),
      dot: Color(0xFF079455),
    ),
    warning: StatusColors(
      text: Color(0xFFB54708),
      surface: Color(0xFFFFF8EB),
      border: Color(0xFFFEDF89),
      dot: Color(0xFFDC6803),
    ),
    info: StatusColors(
      text: Color(0xFF33457D),
      surface: Color(0xFFEFF3FB),
      border: Color(0xFFC9D5EF),
      dot: Color(0xFF52659A),
    ),
    error: StatusColors(
      text: Color(0xFFB42318),
      surface: Color(0xFFFEF3F2),
      border: Color(0xFFFECDCA),
      dot: Color(0xFFD92D20),
    ),
    chartCategorical: <Color>[
      Color(0xFF24346A), // navy-700
      Color(0xFFC9970F), // gold-500
      Color(0xFF8093BC), // navy-400
      Color(0xFF35726E), // muted teal
      Color(0xFF6E4E7E), // muted plum
      Color(0xFF8A93AB), // warm grey
    ],
    heatmapRamp: <Color>[
      Color(0xFFFDF9EC), // gold-50
      Color(0xFFF4E09A), // gold-200
      Color(0xFFE0B32F), // gold-400
      Color(0xFFC9970F), // gold-500
      Color(0xFF85610D), // gold-700
    ],
    shadowLow: <BoxShadow>[
      BoxShadow(color: Color(0x0F131C3D), blurRadius: 3, offset: Offset(0, 1)),
      BoxShadow(color: Color(0x0A131C3D), blurRadius: 12, offset: Offset(0, 2)),
    ],
    shadowMedium: <BoxShadow>[
      BoxShadow(color: Color(0x14131C3D), blurRadius: 20, offset: Offset(0, 6)),
      BoxShadow(color: Color(0x0A131C3D), blurRadius: 4, offset: Offset(0, 2)),
    ],
    shadowHigh: <BoxShadow>[
      BoxShadow(color: Color(0x1F131C3D), blurRadius: 32, offset: Offset(0, 12)),
      BoxShadow(color: Color(0x0D131C3D), blurRadius: 8, offset: Offset(0, 4)),
    ],
    heroSurface: Color(0xFF131C3D),
    heroBorder: Color(0x8CC9970F),
    heroText: Color(0xFFECCB5F),
    heroLabel: Color(0xFFECCB5F),
  );

  static const PlutusTokens dark = PlutusTokens(
    bg: Color(0xFF0C1120),
    surface: Color(0xFF131A2E),
    surfaceSubtle: Color(0xFF1A2340),
    border: Color(0xFF232D4A),
    borderStrong: Color(0xFF33405F),
    text: Color(0xFFEDF0F7),
    textSecondary: Color(0xFFAAB4CE),
    textMuted: Color(0xFF6E7A99),
    brandNavy: Color(0xFFB3BFDB),
    gold: Color(0xFFE0B32F),
    goldHover: Color(0xFFECCB5F),
    goldWeak: Color(0x1FE0B32F),
    goldText: Color(0xFFECCB5F),
    onGold: Color(0xFF0C122A),
    success: StatusColors(
      text: Color(0xFF7BE0AC),
      surface: Color(0xFF11291D),
      border: Color(0xFF1D4A31),
      dot: Color(0xFF3CCF8E),
    ),
    warning: StatusColors(
      text: Color(0xFFF0A94B),
      surface: Color(0xFF2B1F0E),
      border: Color(0xFF5C4413),
      dot: Color(0xFFE8912D),
    ),
    info: StatusColors(
      text: Color(0xFFA9BCE8),
      surface: Color(0xFF16213D),
      border: Color(0xFF2A3A63),
      dot: Color(0xFF7288B5),
    ),
    error: StatusColors(
      text: Color(0xFFF49A92),
      surface: Color(0xFF2C1512),
      border: Color(0xFF5C221C),
      dot: Color(0xFFE5544B),
    ),
    chartCategorical: <Color>[
      Color(0xFFB3BFDB), // navy-300
      Color(0xFFE0B32F), // gold-400
      Color(0xFF8093BC), // navy-400
      Color(0xFF5FA39E), // brightened teal
      Color(0xFFA886B8), // brightened plum
      Color(0xFF6E7A99), // muted slate
    ],
    heatmapRamp: <Color>[
      Color(0x1FE0B32F),
      Color(0x3DE0B32F),
      Color(0x66E0B32F),
      Color(0x99E0B32F),
      Color(0xCCE0B32F),
    ],
    shadowLow: <BoxShadow>[
      BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 2)),
    ],
    shadowMedium: <BoxShadow>[
      BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, 6)),
    ],
    shadowHigh: <BoxShadow>[
      BoxShadow(color: Color(0x55000000), blurRadius: 40, offset: Offset(0, 12)),
    ],
    heroSurface: Color(0xFF131A2E),
    heroBorder: Color(0x8CE0B32F),
    heroText: Color(0xFFECCB5F),
    heroLabel: Color(0xFFECCB5F),
  );

  @override
  PlutusTokens copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceSubtle,
    Color? border,
    Color? borderStrong,
    Color? text,
    Color? textSecondary,
    Color? textMuted,
    Color? brandNavy,
    Color? gold,
    Color? goldHover,
    Color? goldWeak,
    Color? goldText,
    Color? onGold,
    StatusColors? success,
    StatusColors? warning,
    StatusColors? info,
    StatusColors? error,
    List<Color>? chartCategorical,
    List<Color>? heatmapRamp,
    List<BoxShadow>? shadowLow,
    List<BoxShadow>? shadowMedium,
    List<BoxShadow>? shadowHigh,
    Color? heroSurface,
    Color? heroBorder,
    Color? heroText,
    Color? heroLabel,
  }) {
    return PlutusTokens(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      text: text ?? this.text,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      brandNavy: brandNavy ?? this.brandNavy,
      gold: gold ?? this.gold,
      goldHover: goldHover ?? this.goldHover,
      goldWeak: goldWeak ?? this.goldWeak,
      goldText: goldText ?? this.goldText,
      onGold: onGold ?? this.onGold,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      error: error ?? this.error,
      chartCategorical: chartCategorical ?? this.chartCategorical,
      heatmapRamp: heatmapRamp ?? this.heatmapRamp,
      shadowLow: shadowLow ?? this.shadowLow,
      shadowMedium: shadowMedium ?? this.shadowMedium,
      shadowHigh: shadowHigh ?? this.shadowHigh,
      heroSurface: heroSurface ?? this.heroSurface,
      heroBorder: heroBorder ?? this.heroBorder,
      heroText: heroText ?? this.heroText,
      heroLabel: heroLabel ?? this.heroLabel,
    );
  }

  @override
  PlutusTokens lerp(covariant PlutusTokens? other, double t) {
    if (other == null) return this;
    return PlutusTokens(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      text: Color.lerp(text, other.text, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      brandNavy: Color.lerp(brandNavy, other.brandNavy, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      goldHover: Color.lerp(goldHover, other.goldHover, t)!,
      goldWeak: Color.lerp(goldWeak, other.goldWeak, t)!,
      goldText: Color.lerp(goldText, other.goldText, t)!,
      onGold: Color.lerp(onGold, other.onGold, t)!,
      success: StatusColors.lerp(success, other.success, t),
      warning: StatusColors.lerp(warning, other.warning, t),
      info: StatusColors.lerp(info, other.info, t),
      error: StatusColors.lerp(error, other.error, t),
      chartCategorical: t < 0.5 ? chartCategorical : other.chartCategorical,
      heatmapRamp: t < 0.5 ? heatmapRamp : other.heatmapRamp,
      shadowLow: BoxShadow.lerpList(shadowLow, other.shadowLow, t) ?? shadowLow,
      shadowMedium:
          BoxShadow.lerpList(shadowMedium, other.shadowMedium, t) ?? shadowMedium,
      shadowHigh: BoxShadow.lerpList(shadowHigh, other.shadowHigh, t) ?? shadowHigh,
      heroSurface: Color.lerp(heroSurface, other.heroSurface, t)!,
      heroBorder: Color.lerp(heroBorder, other.heroBorder, t)!,
      heroText: Color.lerp(heroText, other.heroText, t)!,
      heroLabel: Color.lerp(heroLabel, other.heroLabel, t)!,
    );
  }
}

/// `context.tokens` — the single access point for brightness-dependent
/// design tokens. Registered on both themes in [AppTheme].
extension PlutusTokensX on BuildContext {
  PlutusTokens get tokens => Theme.of(this).extension<PlutusTokens>()!;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/theme/plutus_tokens_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```powershell
git add lib/theme/plutus_tokens.dart test/theme/plutus_tokens_test.dart
git commit -m "feat(theme): add PlutusTokens ThemeExtension with gold/navy values"
```

---

### Task 3: WCAG AA contrast test

**Files:**
- Test: `test/theme/contrast_test.dart` (create)

**Interfaces:**
- Consumes: `PlutusTokens.light` / `PlutusTokens.dark` / `StatusColors` from Task 2.
- Produces: the enforcement gate for spec §3.6 — if any future token edit breaks AA, this test fails.

- [ ] **Step 1: Write the test (expected to pass immediately — it validates Task 2's values)**

Create `test/theme/contrast_test.dart`:

```dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/theme/plutus_tokens.dart';

double _channel(double c) =>
    c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) =>
    0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b);

double _ratio(Color fg, Color bg) {
  final double l1 = _luminance(fg);
  final double l2 = _luminance(bg);
  final double lighter = math.max(l1, l2);
  final double darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

/// Composites a possibly-translucent [fg] over an opaque [bg] so alpha
/// tokens (e.g. dark goldWeak) are measured as actually rendered.
Color _flatten(Color fg, Color bg) => Color.alphaBlend(fg, bg);

void _check(String name, Color fg, Color bg, double min) {
  final double r = _ratio(fg, bg);
  expect(r, greaterThanOrEqualTo(min),
      reason: '$name: ${r.toStringAsFixed(2)}:1 < $min:1');
}

void main() {
  for (final (String theme, PlutusTokens t) in <(String, PlutusTokens)>[
    ('light', PlutusTokens.light),
    ('dark', PlutusTokens.dark),
  ]) {
    group('WCAG AA — $theme', () {
      test('body text on all neutral surfaces >= 4.5', () {
        for (final (String s, Color bg) in <(String, Color)>[
          ('bg', t.bg),
          ('surface', t.surface),
          ('surfaceSubtle', t.surfaceSubtle),
        ]) {
          _check('$theme text/$s', t.text, bg, 4.5);
          _check('$theme textSecondary/$s', t.textSecondary, bg, 4.5);
          _check('$theme textMuted/$s (caption-only, large-text AA)',
              t.textMuted, bg, 3.0);
        }
      });

      test('gold pairings >= 4.5', () {
        _check('$theme goldText/bg', t.goldText, t.bg, 4.5);
        _check('$theme goldText/surface', t.goldText, t.surface, 4.5);
        _check('$theme goldText/goldWeak', t.goldText,
            _flatten(t.goldWeak, t.surface), 4.5);
        _check('$theme onGold/gold', t.onGold, t.gold, 4.5);
        _check('$theme onGold/goldHover', t.onGold, t.goldHover, 4.5);
      });

      test('brand navy readable on canvas >= 4.5', () {
        _check('$theme brandNavy/bg', t.brandNavy, t.bg, 4.5);
        _check('$theme brandNavy/surface', t.brandNavy, t.surface, 4.5);
      });

      test('status text on status surface >= 4.5', () {
        for (final (String name, StatusColors s) in <(String, StatusColors)>[
          ('success', t.success),
          ('warning', t.warning),
          ('info', t.info),
          ('error', t.error),
        ]) {
          _check('$theme $name.text/$name.surface', s.text,
              _flatten(s.surface, t.surface), 4.5);
        }
      });

      test('hero card figure >= 4.5', () {
        _check('$theme heroText/heroSurface', t.heroText, t.heroSurface, 4.5);
        _check('$theme heroLabel/heroSurface', t.heroLabel, t.heroSurface, 4.5);
      });
    });
  }
}
```

- [ ] **Step 2: Run the test**

Run: `flutter test test/theme/contrast_test.dart`
Expected: PASS (10 tests). If any pair fails, nudge the failing token value in `lib/theme/plutus_tokens.dart` toward more contrast (darker on light theme, lighter on dark theme) until it passes — the thresholds are the rule and never change (spec §3.4/§3.6). Record any nudge in the commit message.

- [ ] **Step 3: Commit**

```powershell
git add test/theme/contrast_test.dart
git commit -m "test(theme): enforce WCAG AA contrast across all token pairings"
```

---

### Task 4: Static scales — `AppSpacing` dual scale, `AppRadius` revalue

**Files:**
- Modify: `lib/theme/app_spacing.dart` (whole file is 13 lines)
- Modify: `lib/theme/app_radius.dart:18-40`

**Interfaces:**
- Produces: `AppSpacing.componentXs/Sm/Md/Lg/Xl/Xxl` (4/8/12/16/20/24), `AppSpacing.layoutSm/Md/Lg/Xl` (24/32/48/64); `AppRadius.button` (12), `AppRadius.sheet` (20); revalued `AppRadius.input` (10), `card` (16), `surface` (20), `iconButton` (10). Existing names (`xs..xxxl`, `pill`, `borderCard`, …) keep working.

- [ ] **Step 1: Extend `AppSpacing`**

Replace the body of `lib/theme/app_spacing.dart` with:

```dart
/// Standardized spacing on a 4pt grid, split into two scales (spec §2.2):
/// the component scale spaces content *inside* a card/button/field; the
/// layout scale spaces sections and cards *apart*. Keeping them named
/// separately stops internal padding drifting into structural rhythm.
class AppSpacing {
  AppSpacing._();

  // ── Legacy generic scale (kept for existing call-sites) ──
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  // ── Component scale: padding and gaps inside a component ──
  static const double componentXs = 4;
  static const double componentSm = 8;
  static const double componentMd = 12;
  static const double componentLg = 16;
  static const double componentXl = 20;
  static const double componentXxl = 24;

  // ── Layout scale: space between sections and cards ──
  static const double layoutSm = 24;
  static const double layoutMd = 32;
  static const double layoutLg = 48;
  static const double layoutXl = 64;
}
```

- [ ] **Step 2: Revalue `AppRadius` component tokens**

In `lib/theme/app_radius.dart`, keep the generic scale (`xs..xl`) and the `BorderRadius` statics, and change the component-named section to:

```dart
  // ── Component-named tokens (spec §2.2) ──
  /// Fully-rounded pill — chips and badges ONLY (buttons are `button`).
  static const double pill = 999;
  /// Button radius.
  static const double button = 12;
  /// Card radius (`Card`, list cards, balance card).
  static const double card = 16;
  /// Sheet / dialog radius.
  static const double sheet = 20;
  /// Surface radius — legacy alias of [sheet].
  static const double surface = sheet;
  /// Input field radius.
  static const double input = 10;
  /// Small icon-button radius.
  static const double iconButton = 10;
```

And add one `BorderRadius` static alongside the existing ones:

```dart
  static BorderRadius borderButton = BorderRadius.circular(button);
```

(The existing `borderCard`, `borderSurface`, `borderInput`, `borderIconButton` statics pick up the new values automatically because they derive from the constants.)

- [ ] **Step 3: Verify**

```powershell
flutter analyze lib/theme; flutter test
```

Expected: no new errors; all tests pass (radius changes are value-only).

- [ ] **Step 4: Commit**

```powershell
git add lib/theme/app_spacing.dart lib/theme/app_radius.dart
git commit -m "feat(theme): dual spacing scale and calm radius values"
```

---

### Task 5: Revalue `AppColors` to gold/navy

**Files:**
- Modify: `lib/theme/app_colors.dart` (values only — every function signature and member name stays identical so the ~100 call-sites keep compiling)

**Interfaces:**
- Consumes: nothing new.
- Produces: the transitional re-tint. All `AppColors.*` reads across the app now resolve to gold/navy values. Deprecation happens in Task 6 (separate commit so this diff is pure values).

- [ ] **Step 1: Apply the value mapping**

In `lib/theme/app_colors.dart`, change ONLY the color literals listed below (current line numbers in parentheses). Update each member's trailing comment to name the new value (e.g. `// gold-500`):

| Member (line) | New value |
|---|---|
| `primary` (13) | `Color(0xFFC9970F)` gold-500 |
| `primaryStrong` (14) | `Color(0xFFA67A0B)` gold-600 |
| `primarySoft` (15) | `Color(0xFFFDF9EC)` gold-50 |
| `primaryDark` (17) | `Color(0xFFE0B32F)` gold-400 |
| `primaryStrongDark` (18) | `Color(0xFFECCB5F)` gold-300 |
| `primarySoftDark` (19) | `Color(0x1FE0B32F)` gold-400 @12% |
| `accent` (23) | `Color(0xFFFAF0CE)` gold-100 |
| `accentDark` (25) | `Color(0xFFECCB5F)` gold-300 |
| `ctaButtonLight` (28) | `Color(0xFFC9970F)` gold-500 |
| `ctaButtonDark` (29) | `Color(0xFFE0B32F)` gold-400 |
| `backgroundLight` (32) | `Color(0xFFF7F8FA)` |
| `surfaceLight` (33) | unchanged `Color(0xFFFFFFFF)` |
| `surfaceMutedLight` (34) | `Color(0xFFF1F3F6)` |
| `surfaceElevatedLight` (35) | unchanged `Color(0xFFFFFFFF)` |
| `borderLight` (36) | `Color(0xFFE5E8EE)` |
| `dividerLight` (37) | `Color(0xFFE5E8EE)` |
| `backgroundDark` (40) | `Color(0xFF0C1120)` |
| `surfaceDark` (41) | `Color(0xFF131A2E)` |
| `surfaceMidDark` (42) | `Color(0xFF1A2340)` |
| `surfaceElevatedDark` (43) | `Color(0xFF1A2340)` |
| `borderDark` (44) | `Color(0xFF232D4A)` |
| `dividerDark` (45) | `Color(0xFF232D4A)` |
| `textOnLight` (55) | `Color(0xFF131C3D)` navy-900 |
| `textOnLightSecondary` (56) | `Color(0xFF4A5573)` |
| `textOnLightTertiary` (57) | `Color(0xFF7E88A3)` |
| `textOnDark` (60) | `Color(0xFFEDF0F7)` |
| `textOnDarkSecondary` (61) | `Color(0xFFAAB4CE)` |
| `textOnDarkTertiary` (62) | `Color(0xFF6E7A99)` |
| `error` (65) | `Color(0xFFD92D20)` |
| `success` (66) | `Color(0xFF079455)` |
| `warning` (67) | `Color(0xFFDC6803)` |
| `info` (68) | `Color(0xFF52659A)` |
| `chartPaletteLight` (73-82) | `[Color(0xFF24346A), Color(0xFFC9970F), Color(0xFF8093BC), Color(0xFF35726E), Color(0xFF6E4E7E), Color(0xFF8A93AB)]` |
| `chartPaletteDark` (84-93) | `[Color(0xFFB3BFDB), Color(0xFFE0B32F), Color(0xFF8093BC), Color(0xFF5FA39E), Color(0xFFA886B8), Color(0xFF6E7A99)]` |
| `profileAccent` (99) | `Color(0xFF52659A)` |
| `budgetAccent` (100) | `Color(0xFF33457D)` |
| `categoryBudgetAccent` (101) | `Color(0xFF52659A)` |
| `historyAccent` (102) | `Color(0xFF33457D)` |
| `cashflowAccent` (103) | `Color(0xFF24346A)` |
| `expenseAccent` (104) | `Color(0xFFD92D20)` |
| `incomeAccent` (105) | `Color(0xFF079455)` |
| `savingsAccent` (106) | `Color(0xFFC9970F)` |
| `netWorthAccent` (107) | `Color(0xFFC9970F)` |
| `heatmapAccent` (108) | `Color(0xFFC9970F)` |
| `marketAccent` (109) | `Color(0xFF52659A)` |
| `billsAccent` (110) | `Color(0xFF33457D)` |
| `taxAccent` (111) | `Color(0xFF52659A)` |
| `importAccent` (112) | `Color(0xFF52659A)` |
| `exportAccent` (113) | `Color(0xFF33457D)` |
| `_positiveLight` (283) | `Color(0xFF067647)` |
| `_positiveDark` (284) | `Color(0xFF3CCF8E)` |
| `_negativeLight` (285) | `Color(0xFFB42318)` |
| `_negativeDark` (286) | `Color(0xFFF49A92)` |

Also update these two method bodies:

- `ctaButtonForeground` (line 160): change `=> Colors.white;` to `=> const Color(0xFF0C122A);` — gold CTAs carry navy ink, both modes (spec §3.2 `onGold`).
- `gridLine` / `borderLine` (lines 165-171): replace the black/white alpha literals with navy-tinted hairlines:

```dart
  static Color gridLine(Brightness b) => b == Brightness.dark
      ? Colors.white.withValues(alpha: 0.06)
      : const Color(0xFF131C3D).withValues(alpha: 0.06);

  static Color borderLine(Brightness b) => b == Brightness.dark
      ? Colors.white.withValues(alpha: 0.10)
      : const Color(0xFF131C3D).withValues(alpha: 0.10);
```

Finally, update the class doc comment (lines 3-8) to describe the gold/navy system and note the class is a transitional shim over `PlutusTokens`.

The `dashboardAccents` registry (lines 241-257) needs no edit — it references the accent constants. `menuBackground`, `backgroundLightStart/End` aliases (49-52) also update transitively. The `editAccent`/`editOutline`/`editSnapGlow`/`editHandleFill` family (263-280) derives from `brand()` and now reads gold automatically.

- [ ] **Step 2: Run the full test suite**

Run: `flutter test`
Expected: PASS. Two suites compute from these values rather than pinning them (`test/theme/on_accent_contrast_test.dart` derives foregrounds via luminance; `test/widgets/chart_theme_test.dart` only tests axis-label logic). If any other test pins an old magenta/violet literal, update the expectation to the new value from the table above.

- [ ] **Step 3: Visual smoke check**

```powershell
flutter run -d chrome --dart-define-from-file=app.env
```

Expected: app boots; canvas is near-white (light) with gold/navy accents — no magenta/pink anywhere. Close after checking login + dashboard.

- [ ] **Step 4: Commit**

```powershell
git add lib/theme/app_colors.dart
git commit -m "feat(theme): revalue AppColors palette to gold/navy system"
```

---

### Task 6: Deprecate the shims + neutralize `AppElevation` glows + revalue `AppGradients`

**Files:**
- Modify: `lib/theme/app_colors.dart:9` (class annotation)
- Modify: `lib/theme/app_elevation.dart` (glow values + class annotation; `AppMotion` in the same file is NOT deprecated — it stays per spec §2.2)
- Modify: `lib/theme/app_gradients.dart` (values + class annotation)
- Modify: `analysis_options.yaml:12-25`

**Interfaces:**
- Produces: `@Deprecated` markers that make every remaining legacy usage discoverable (via IDE strikethrough and `grep`), while `analysis_options.yaml` keeps `flutter analyze` output clean until PR4 deletes the shims.

- [ ] **Step 1: Annotate the shim classes**

Directly above `class AppColors {` add:

```dart
@Deprecated('Transitional shim — use context.tokens (PlutusTokens). Removed in PR4.')
```

Add the same annotation above `class AppElevation {` and `class AppGradients {`. Do NOT annotate `AppMotion`.

- [ ] **Step 2: Neutralize the tinted glows in `app_elevation.dart`**

Replace the two private glow constants (lines 13-16) and the three glow methods' shadow colors so nothing magenta/violet survives:

```dart
  /// Neutral navy-tinted halo — legacy alias for the low shadow set.
  static const Color _glowLight = Color(0x14131C3D);
  static const Color _glowDark = Color(0x33000000);
```

- `brandGlow` (lines 83-97): keep the structure, colors become `_glowDark` / `_glowLight` (they already reference the constants — verify, and reduce dark blurRadius 28→16, light 24→12 so the halo reads as a soft neutral shadow, offsets `(0, 4)` both).
- `fabGlow` (lines 101-107): ignore the passed color for tinting; return a neutral medium shadow:

```dart
  static List<BoxShadow> fabGlow(Color brand) => const <BoxShadow>[
        BoxShadow(
          color: Color(0x24131C3D),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ];
```

- `floatingNav` (lines 110-134): replace both brightness variants with neutral shadows — dark: single `BoxShadow(color: Color(0x59000000), blurRadius: 24, offset: Offset(0, 8))`; light: single `BoxShadow(color: Color(0x1F131C3D), blurRadius: 24, offset: Offset(0, 8))`.
- Update the class doc comment (lines 3-8): shadows are now neutral; brand glows are gone.

- [ ] **Step 3: Revalue `AppGradients` to near-flat navy/gold**

Replace the four gradient definitions (keep names and the `balanceCard(Brightness)` switcher):

```dart
  /// Hero balance card (dark) — near-flat deep-navy surface.
  static const LinearGradient balanceCardDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF1A2340), Color(0xFF131A2E)],
  );

  /// Hero balance card (light) — near-flat navy-800→900.
  static const LinearGradient balanceCardLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF1A2650), Color(0xFF131C3D)],
  );

  /// Dark-canvas wash — barely-there navy fade.
  static const LinearGradient heroBackgroundDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0xFF10162B), Color(0xFF0C1120)],
  );

  /// CTA gradient (dark) — near-flat gold; solid gold fills are preferred.
  static const LinearGradient ctaButtonDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFE0B32F), Color(0xFFC9970F)],
  );
```

Note: `AppGradients` currently references `AppColors.primaryDark` etc. — the replacements above use literals, so also delete the now-unused `import 'app_colors.dart';` if the analyzer flags it.

- [ ] **Step 4: Silence in-package deprecation noise until PR4**

In `analysis_options.yaml`, add an `analyzer:` block above the existing `linter:` block (line 12):

```yaml
analyzer:
  errors:
    # PR1-PR3 of the gold/navy redesign intentionally keep deprecated
    # AppColors/AppElevation/AppGradients shims alive while call-sites
    # migrate to PlutusTokens. Remove this override in PR4 with the shims.
    deprecated_member_use_from_same_package: ignore
```

- [ ] **Step 5: Verify**

```powershell
flutter analyze; flutter test
```

Expected: no new errors (baseline: pre-existing errors in `packages/dashboard/example` only); tests pass.

- [ ] **Step 6: Commit**

```powershell
git add lib/theme/app_colors.dart lib/theme/app_elevation.dart lib/theme/app_gradients.dart analysis_options.yaml
git commit -m "feat(theme): deprecate legacy token shims, neutralize glows and gradients"
```

---

### Task 7: Typography roles

**Files:**
- Modify: `lib/theme/app_text_styles.dart`

**Interfaces:**
- Consumes: font families bundled in Task 1.
- Produces: revalued role styles + two new statics later PRs use verbatim: `AppTextStyles.overlineStyle` (`TextStyle`, 11/600/+0.66ls/UPPERCASE-by-convention) and `AppTextStyles.heroSerifStyle` (`TextStyle`, CormorantGaramond 600, 40/1.1). Existing names all survive.

- [ ] **Step 1: Revalue the semantic role styles (spec §4 table)**

In the "Legacy alias" sections of `lib/theme/app_text_styles.dart` (size constants at lines 40-46, styles at lines 163-210), set:

| Constant | New size | Style changes |
|---|---|---|
| `display` (40) | 32 | `displayStyle`: w700 (was w800), letterSpacing −0.64, height 1.15 |
| `heading` (41) | 24 | `headingStyle`: w600 (was w800), letterSpacing −0.3, height 1.3 |
| `title` (42) | 18 | `titleStyle`: w600 (was w700), letterSpacing −0.1, height 1.3 |
| `subtitle` (43) | 16 | `subtitleStyle`: w600 (was w700), letterSpacing 0, height 1.4 |
| `body` (44) | 15 (unchanged) | `bodyStyle`: w400 (was w500), height 1.5 |
| `label` (45) | 13 (unchanged) | `labelStyle`: w500 (was w600), height 1.4 |
| `caption` (46) | 12 (unchanged) | `captionStyle`: w400 (was w500), height 1.4 |

Leave `bodyStrongStyle` at w600 (drop from w700) — it is the button/emphasis style. Leave the M3-named styles (`displayLargeStyle` … `labelSmallStyle`, lines 65-158) untouched; they follow the M3 spec and the `TextTheme` mapping in `app_theme.dart` consumes them.

- [ ] **Step 2: Add the two new role styles**

After `numericStyle` (line 214-219), add:

```dart
  /// Uppercase micro-label — table headers, group labels, hero-card
  /// eyebrows. Callers pass text through `.toUpperCase()`.
  static final TextStyle overlineStyle = _base.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.66,
    height: 1.3,
  );

  /// Classical serif accent (spec §4): Cormorant Garamond 600. Used in
  /// exactly two places — the dashboard hero net-worth figure and the
  /// auth tagline. Everywhere else is Inter.
  static final TextStyle heroSerifStyle = const TextStyle(
    fontFamily: 'CormorantGaramond',
    fontFamilyFallback: <String>['Georgia', 'Times New Roman', 'serif'],
    fontVariations: <FontVariation>[FontVariation('wght', 600)],
  ).copyWith(
    fontSize: 40,
    fontWeight: FontWeight.w600,
    height: 1.1,
    letterSpacing: 0,
  );
```

- [ ] **Step 3: Update the class doc comment** (lines 3-13) to document the role table including `overline`, `numeric`, and `heroSerif`.

- [ ] **Step 4: Verify**

```powershell
flutter analyze lib/theme; flutter test
```

Expected: clean; existing tests pass (they don't pin font sizes).

- [ ] **Step 5: Commit**

```powershell
git add lib/theme/app_text_styles.dart
git commit -m "feat(theme): calm type roles, overline and Cormorant heroSerif styles"
```

---

### Task 8: Register `PlutusTokens` on `ThemeData` + rebuild `ColorScheme`

**Files:**
- Modify: `lib/theme/app_theme.dart:1-32` (imports, `_build` locals, `ColorScheme`) and the `ThemeData` constructor call (add `extensions:`)
- Test: `test/theme/app_theme_test.dart` (create)

**Interfaces:**
- Consumes: `PlutusTokens` (Task 2).
- Produces: `Theme.of(context).extension<PlutusTokens>()` non-null under both `AppTheme.light()`/`AppTheme.dark()` — the contract `context.tokens` relies on. Also a local `final PlutusTokens t` inside `_build` that Tasks 9-10 reference.

- [ ] **Step 1: Write the failing test**

Create `test/theme/app_theme_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/theme/app_theme.dart';
import 'package:plutus_fe_prototype/theme/plutus_tokens.dart';

void main() {
  group('AppTheme registers PlutusTokens', () {
    test('light theme carries PlutusTokens.light', () {
      final PlutusTokens? t = AppTheme.light().extension<PlutusTokens>();
      expect(t, isNotNull);
      expect(t!.bg, PlutusTokens.light.bg);
      expect(t.gold, PlutusTokens.light.gold);
    });

    test('dark theme carries PlutusTokens.dark', () {
      final PlutusTokens? t = AppTheme.dark().extension<PlutusTokens>();
      expect(t, isNotNull);
      expect(t!.bg, PlutusTokens.dark.bg);
    });

    test('ThemeData.lerp interpolates the extension (theme animation)', () {
      final ThemeData mid = ThemeData.lerp(AppTheme.light(), AppTheme.dark(), 0.5);
      final PlutusTokens? t = mid.extension<PlutusTokens>();
      expect(t, isNotNull);
      expect(t!.bg,
          Color.lerp(PlutusTokens.light.bg, PlutusTokens.dark.bg, 0.5));
    });

    testWidgets('context.tokens resolves inside the widget tree', (tester) async {
      late PlutusTokens seen;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        home: Builder(builder: (BuildContext context) {
          seen = context.tokens;
          return const SizedBox();
        }),
      ));
      expect(seen.surface, PlutusTokens.light.surface);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/theme/app_theme_test.dart`
Expected: FAIL — `extension<PlutusTokens>()` returns null (not registered yet).

- [ ] **Step 3: Register the extension and rebuild the ColorScheme**

In `lib/theme/app_theme.dart`:

1. Add import: `import 'plutus_tokens.dart';`
2. At the top of `_build` (after line 15), add the token local every component theme will use:

```dart
    final PlutusTokens t =
        isDark ? PlutusTokens.dark : PlutusTokens.light;
```

3. Replace the `ColorScheme.fromSeed` block (lines 25-32) with an explicit scheme so Material defaults derive from the real palette:

```dart
    final ColorScheme scheme = ColorScheme(
      brightness: brightness,
      primary: t.gold,
      onPrimary: t.onGold,
      secondary: t.brandNavy,
      onSecondary: isDark ? t.bg : Colors.white,
      surface: t.surface,
      onSurface: t.text,
      error: t.error.dot,
      onError: Colors.white,
      outline: t.borderStrong,
      outlineVariant: t.border,
      surfaceContainerHighest: t.surfaceSubtle,
      shadow: Colors.black,
    );
```

4. In the `ThemeData(...)` call, add:

```dart
      extensions: <ThemeExtension<dynamic>>[t],
```

5. Keep the existing locals (`seed`, `bg`, `surface`, `textPrimary`, …) working for now — they still feed the component themes that Tasks 9-10 replace. Where a local duplicates a token (e.g. `bg`), you may re-point it at `t` (e.g. `final Color bg = t.bg;`) but do not remove any yet.

- [ ] **Step 4: Run tests**

Run: `flutter test`
Expected: PASS (new file 4/4; full suite green).

- [ ] **Step 5: Commit**

```powershell
git add lib/theme/app_theme.dart test/theme/app_theme_test.dart
git commit -m "feat(theme): register PlutusTokens extension and explicit gold/navy ColorScheme"
```

---

### Task 9: Component themes — buttons + inputs

**Files:**
- Modify: `lib/theme/app_theme.dart:119-200` (filled/elevated/outlined/text button themes, input decoration theme)
- Test: `test/theme/app_theme_test.dart` (extend)

**Interfaces:**
- Consumes: `t` local (Task 8), `AppRadius.button/input` (Task 4), `AppTextStyles.bodyStrongStyle` (Task 7).
- Produces: themed Material buttons — every existing `FilledButton`/`ElevatedButton`/`OutlinedButton`/`TextButton`/`TextField` in the app restyles without call-site edits.

- [ ] **Step 1: Write failing assertions**

Append to the group in `test/theme/app_theme_test.dart`:

```dart
    test('primary buttons are gold with navy ink, 44px, radius 12', () {
      final ThemeData theme = AppTheme.light();
      final ButtonStyle style = theme.filledButtonTheme.style!;
      expect(style.backgroundColor!.resolve(<WidgetState>{}),
          PlutusTokens.light.gold);
      expect(style.backgroundColor!.resolve(<WidgetState>{WidgetState.hovered}),
          PlutusTokens.light.goldHover);
      expect(style.foregroundColor!.resolve(<WidgetState>{}),
          PlutusTokens.light.onGold);
      expect(style.minimumSize!.resolve(<WidgetState>{}),
          const Size(64, 44));
      final OutlinedBorder shape = style.shape!.resolve(<WidgetState>{})!;
      expect(shape, isA<RoundedRectangleBorder>());
      expect((shape as RoundedRectangleBorder).borderRadius,
          BorderRadius.circular(12));
    });

    test('inputs use hairline borderStrong at rest and 2px gold on focus', () {
      final InputDecorationTheme d = AppTheme.light().inputDecorationTheme;
      final OutlineInputBorder enabled = d.enabledBorder! as OutlineInputBorder;
      expect(enabled.borderSide.color, PlutusTokens.light.borderStrong);
      expect(enabled.borderSide.width, 1);
      final OutlineInputBorder focused = d.focusedBorder! as OutlineInputBorder;
      expect(focused.borderSide.color, PlutusTokens.light.gold);
      expect(focused.borderSide.width, 2);
    });
```

- [ ] **Step 2: Run to verify they fail**

Run: `flutter test test/theme/app_theme_test.dart`
Expected: FAIL — current buttons are 56px pills with `ctaBg`; inputs are borderless-filled.

- [ ] **Step 3: Replace the button themes**

In `app_theme.dart`, replace the `filledButtonTheme`, `elevatedButtonTheme`, `outlinedButtonTheme`, and `textButtonTheme` entries with:

```dart
      // Primary CTA: gold fill + navy ink (spec §5). 44px, radius 12.
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
            if (s.contains(WidgetState.disabled)) return t.surfaceSubtle;
            if (s.contains(WidgetState.pressed) || s.contains(WidgetState.hovered)) {
              return t.goldHover;
            }
            return t.gold;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) =>
              s.contains(WidgetState.disabled) ? t.textMuted : t.onGold),
          textStyle: WidgetStatePropertyAll<TextStyle>(
              AppTextStyles.bodyStrongStyle),
          minimumSize: const WidgetStatePropertyAll<Size>(Size(64, 44)),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
              EdgeInsets.symmetric(horizontal: AppSpacing.componentXxl)),
          shape: WidgetStatePropertyAll<OutlinedBorder>(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button))),
          elevation: const WidgetStatePropertyAll<double>(0),
        ),
      ),
      // ElevatedButton mirrors FilledButton so legacy call-sites match.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
            if (s.contains(WidgetState.disabled)) return t.surfaceSubtle;
            if (s.contains(WidgetState.pressed) || s.contains(WidgetState.hovered)) {
              return t.goldHover;
            }
            return t.gold;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) =>
              s.contains(WidgetState.disabled) ? t.textMuted : t.onGold),
          textStyle: WidgetStatePropertyAll<TextStyle>(
              AppTextStyles.bodyStrongStyle),
          minimumSize: const WidgetStatePropertyAll<Size>(Size(64, 44)),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
              EdgeInsets.symmetric(horizontal: AppSpacing.componentXxl)),
          shape: WidgetStatePropertyAll<OutlinedBorder>(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button))),
          elevation: const WidgetStatePropertyAll<double>(0),
          shadowColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
        ),
      ),
      // Ghost button: surface + strong hairline + navy text.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) =>
              s.contains(WidgetState.disabled) ? t.textMuted : t.text),
          backgroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) =>
              s.contains(WidgetState.hovered) ? t.surfaceSubtle : t.surface),
          side: WidgetStatePropertyAll<BorderSide>(
              BorderSide(color: t.borderStrong)),
          textStyle: WidgetStatePropertyAll<TextStyle>(
              AppTextStyles.bodyStrongStyle),
          minimumSize: const WidgetStatePropertyAll<Size>(Size(64, 44)),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
              EdgeInsets.symmetric(horizontal: AppSpacing.componentXxl)),
          shape: WidgetStatePropertyAll<OutlinedBorder>(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button))),
        ),
      ),
      // Tertiary: quiet navy text button.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? t.brandNavy : const Color(0xFF33457D),
          textStyle: AppTextStyles.bodyStrongStyle,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.componentMd),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button)),
        ),
      ),
```

- [ ] **Step 4: Replace the input decoration theme**

Replace the `inputDecorationTheme` entry with (note: the outer gold focus halo from spec §5 cannot be expressed in `InputDecorationTheme`; PR1 ships the 2px gold border and a subtle gold focus fill — the halo arrives with the `AppTextField` wrapper when forms migrate in PR2/3):

```dart
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surface,
        focusColor: t.gold.withValues(alpha: 0.06),
        hintStyle: AppTextStyles.bodyStyle.copyWith(color: t.textMuted),
        labelStyle: AppTextStyles.labelStyle.copyWith(color: t.textSecondary),
        helperStyle: AppTextStyles.captionStyle.copyWith(color: t.textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.componentLg,
          vertical: AppSpacing.componentMd,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.borderInput,
          borderSide: BorderSide(color: t.borderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderInput,
          borderSide: BorderSide(color: t.borderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderInput,
          borderSide: BorderSide(color: t.gold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderInput,
          borderSide: BorderSide(color: t.error.dot),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderInput,
          borderSide: BorderSide(color: t.error.dot, width: 2),
        ),
      ),
```

- [ ] **Step 5: Run tests**

Run: `flutter test`
Expected: PASS, including the two new assertions.

- [ ] **Step 6: Commit**

```powershell
git add lib/theme/app_theme.dart test/theme/app_theme_test.dart
git commit -m "feat(theme): gold CTA buttons, ghost buttons and hairline inputs"
```

---

### Task 10: Component themes — chrome (app bar, nav, chips, dialogs, sheets, snackbar, tabs, switch)

**Files:**
- Modify: `lib/theme/app_theme.dart:65-118, 201-257` (remaining component themes)

**Interfaces:**
- Consumes: `t` local, `AppRadius.sheet` (Task 4), `AppTextStyles.overlineStyle/labelStyle` (Task 7).
- Produces: fully-themed Material chrome for PR2/3 screens.

- [ ] **Step 1: Replace the remaining component themes**

In `app_theme.dart`, replace each listed entry:

`appBarTheme` (transparent on canvas; hairline appears on scroll-under via elevation 1 + border-toned shadow):

```dart
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: t.text,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: t.border,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        toolbarHeight: 64,
        titleTextStyle: AppTextStyles.headingStyle.copyWith(color: t.text),
        iconTheme: IconThemeData(color: t.text, size: 24),
      ),
```

`navigationBarTheme` (goldWeak indicator pill behind a navy icon — spec §5; no gold icons on white):

```dart
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: t.goldWeak,
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((Set<WidgetState> s) =>
            AppTextStyles.labelStyle.copyWith(
                color: s.contains(WidgetState.selected)
                    ? t.text
                    : t.textSecondary)),
        iconTheme: WidgetStateProperty.resolveWith((Set<WidgetState> s) =>
            IconThemeData(
                color: s.contains(WidgetState.selected)
                    ? t.text
                    : t.textSecondary)),
      ),
```

`cardTheme` (calm card: radius 16, hairline via shape side — shadow comes from `AppCard` where needed):

```dart
      cardTheme: CardThemeData(
        color: t.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderCard,
          side: BorderSide(color: t.border),
        ),
      ),
```

`dialogTheme` and `bottomSheetTheme` (radius 20 = `AppRadius.sheet`):

```dart
      dialogTheme: DialogThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.25),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSurface),
        titleTextStyle: AppTextStyles.titleStyle.copyWith(color: t.text),
        contentTextStyle: AppTextStyles.bodyStyle.copyWith(color: t.textSecondary),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
      ),
```

`chipTheme` (rest: subtle inset + navy text; selected: goldWeak + goldText — spec §5):

```dart
      chipTheme: ChipThemeData(
        backgroundColor: t.surfaceSubtle,
        selectedColor: isDark
            ? Color.alphaBlend(t.goldWeak, t.surface)
            : t.goldWeak,
        labelStyle: AppTextStyles.labelStyle.copyWith(color: t.text),
        secondaryLabelStyle:
            AppTextStyles.labelStyle.copyWith(color: t.goldText),
        checkmarkColor: t.goldText,
        side: BorderSide(color: t.border),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.componentMd,
          vertical: AppSpacing.componentXs,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderPill),
      ),
```

`tabBarTheme` (navy label, 2px gold underline — the gold underline is the selected-tab indicator from spec §3.2):

```dart
      tabBarTheme: TabBarThemeData(
        labelColor: t.text,
        unselectedLabelColor: t.textSecondary,
        labelStyle: AppTextStyles.bodyStrongStyle,
        unselectedLabelStyle: AppTextStyles.bodyStyle,
        indicatorColor: t.gold,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
      ),
```

`snackBarTheme` (navy-900 slab on light, elevated navy surface on dark):

```dart
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? t.surfaceSubtle : const Color(0xFF131C3D),
        contentTextStyle:
            AppTextStyles.bodyStyle.copyWith(color: const Color(0xFFEDF0F7)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button)),
      ),
```

`switchTheme` (gold when on):

```dart
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) =>
            s.contains(WidgetState.selected) ? t.onGold : t.surface),
        trackColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) =>
            s.contains(WidgetState.selected) ? t.gold : t.borderStrong),
        trackOutlineColor:
            const WidgetStatePropertyAll<Color>(Colors.transparent),
      ),
```

Also update these scalar entries in the same `ThemeData(...)`:
- `scaffoldBackgroundColor`: keep `Colors.transparent` (AppCanvas paints the base — same contract as GlassBackground; the comment at lines 56-57 should mention `AppCanvas`).
- `canvasColor: t.bg`, `dividerColor: t.border`.
- `dividerTheme`: `color: t.border` (space/thickness 1 unchanged).
- `listTileTheme`: `iconColor: t.textSecondary`, `textColor: t.text` (padding/shape unchanged).
- `iconTheme`/`primaryIconTheme`: `color: t.text`.
- The old locals (`seed`, `secondary`, `ctaBg`, `ctaFg`, and the `AppColors.*` reads) should now be unused — delete them and the `import 'app_colors.dart';` if the analyzer confirms nothing references them.

- [ ] **Step 2: Verify**

```powershell
flutter analyze lib/theme; flutter test
```

Expected: no new issues; full suite green.

- [ ] **Step 3: Visual smoke check**

```powershell
flutter run -d chrome --dart-define-from-file=app.env
```

Expected: nav bar shows goldWeak pill indicator; buttons are gold with navy labels; toggle dark mode in Settings — everything re-tints, nothing unreadable.

- [ ] **Step 4: Commit**

```powershell
git add lib/theme/app_theme.dart
git commit -m "feat(theme): calm gold/navy chrome for nav, chips, dialogs, tabs and switches"
```

---

### Task 11: `AppCanvas` + `AppCard` primitives

**Files:**
- Create: `lib/widgets/core/app_canvas.dart`, `lib/widgets/core/app_card.dart`
- Modify: `lib/widgets/glass_container.dart:18` and `lib/widgets/glass_background.dart:8` (add `@Deprecated` annotations only — no behavior change)
- Test: `test/widgets/core/app_card_test.dart` (create)

**Interfaces:**
- Consumes: `context.tokens`, `AppRadius.card`.
- Produces (PR2/3 building blocks):
  - `class AppCanvas extends StatelessWidget { const AppCanvas({super.key, required this.child}); final Widget child; }`
  - `class AppCard extends StatelessWidget { const AppCard({super.key, this.child, this.padding, this.margin, this.width, this.height, this.onTap}); }` — opaque surface, hairline border, radius 16, `shadowLow`; `onTap` non-null wraps an `InkWell`.

- [ ] **Step 1: Write the failing test**

Create `test/widgets/core/app_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/theme/app_theme.dart';
import 'package:plutus_fe_prototype/theme/plutus_tokens.dart';
import 'package:plutus_fe_prototype/widgets/core/app_card.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) {
    return tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: Center(child: child)),
    ));
  }

  testWidgets('AppCard renders surface, hairline border and low shadow',
      (WidgetTester tester) async {
    await pump(tester, const AppCard(child: Text('hello')));
    final Container container = tester.widget<Container>(find.descendant(
        of: find.byType(AppCard), matching: find.byType(Container)));
    final BoxDecoration deco = container.decoration! as BoxDecoration;
    expect(deco.color, PlutusTokens.light.surface);
    expect((deco.border! as Border).top.color, PlutusTokens.light.border);
    expect(deco.borderRadius, BorderRadius.circular(16));
    expect(deco.boxShadow, PlutusTokens.light.shadowLow);
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('AppCard with onTap responds to taps',
      (WidgetTester tester) async {
    int taps = 0;
    await pump(tester, AppCard(onTap: () => taps++, child: const Text('go')));
    await tester.tap(find.text('go'));
    expect(taps, 1);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/widgets/core/app_card_test.dart`
Expected: FAIL — `app_card.dart` does not exist.

- [ ] **Step 3: Implement `lib/widgets/core/app_card.dart`**

```dart
import 'package:flutter/material.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/plutus_tokens.dart';

/// Calm card surface (spec §5): opaque surface, hairline border,
/// radius 16, low shadow. Replaces the legacy [GlassContainer].
class AppCard extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final PlutusTokens t = context.tokens;
    final BorderRadius radius = BorderRadius.circular(AppRadius.card);

    Widget content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.componentLg),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: content,
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: radius,
        border: Border.all(color: t.border),
        boxShadow: t.shadowLow,
      ),
      child: content,
    );
  }
}
```

- [ ] **Step 4: Implement `lib/widgets/core/app_canvas.dart`**

```dart
import 'package:flutter/material.dart';
import '../../theme/plutus_tokens.dart';

/// App-wide canvas (spec §5): neutral background plus one very faint
/// radial gold wash bleeding from the top — the only decorative gradient
/// in the app. Replaces the legacy [GlassBackground].
class AppCanvas extends StatelessWidget {
  final Widget child;

  const AppCanvas({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final PlutusTokens t = context.tokens;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color wash = t.gold.withValues(alpha: isDark ? 0.04 : 0.05);

    return Stack(
      children: <Widget>[
        Positioned.fill(child: ColoredBox(color: t.bg)),
        Positioned(
          top: -320,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Container(
              height: 560,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: <Color>[wash, Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        SafeArea(child: child),
      ],
    );
  }
}
```

Note: because `PlutusTokens.lerp` is registered on the theme (Task 8), theme animation smoothly blends `t.bg`/`t.gold` — no `BrightnessBlend` plumbing needed here, unlike the old `GlassBackground`.

- [ ] **Step 5: Deprecate the glass widgets**

Add above `class GlassContainer` in `lib/widgets/glass_container.dart`:

```dart
@Deprecated('Use AppCard (lib/widgets/core/app_card.dart). Removed in PR4.')
```

Add above `class GlassBackground` in `lib/widgets/glass_background.dart`:

```dart
@Deprecated('Use AppCanvas (lib/widgets/core/app_canvas.dart). Removed in PR4.')
```

- [ ] **Step 6: Run tests**

Run: `flutter test`
Expected: PASS.

- [ ] **Step 7: Commit**

```powershell
git add lib/widgets/core/app_card.dart lib/widgets/core/app_canvas.dart lib/widgets/glass_container.dart lib/widgets/glass_background.dart test/widgets/core/app_card_test.dart
git commit -m "feat(core): AppCard and AppCanvas calm-surface primitives"
```

---

### Task 12: `HeroCard` primitive

**Files:**
- Create: `lib/widgets/core/hero_card.dart`
- Test: `test/widgets/core/hero_card_test.dart` (create)

**Interfaces:**
- Consumes: `context.tokens` hero fields, `AppTextStyles.heroSerifStyle/overlineStyle`, `AppRadius.card`.
- Produces: `class HeroCard extends StatelessWidget { const HeroCard({super.key, required this.label, required this.value, this.footer}); final String label; final String value; final Widget? footer; }` — the dashboard's signature navy+gold-serif moment (PR2 mounts it).

- [ ] **Step 1: Write the failing test**

Create `test/widgets/core/hero_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/theme/app_theme.dart';
import 'package:plutus_fe_prototype/theme/plutus_tokens.dart';
import 'package:plutus_fe_prototype/widgets/core/hero_card.dart';

void main() {
  testWidgets('HeroCard renders navy surface, gold hairline and serif figure',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: const Scaffold(
        body: HeroCard(label: 'Net worth', value: r'$12,345.67'),
      ),
    ));

    expect(find.text('NET WORTH'), findsOneWidget);
    final Text value = tester.widget<Text>(find.text(r'$12,345.67'));
    expect(value.style!.fontFamily, 'CormorantGaramond');
    expect(value.style!.color, PlutusTokens.light.heroText);

    final Container container = tester.widget<Container>(find
        .descendant(of: find.byType(HeroCard), matching: find.byType(Container))
        .first);
    final BoxDecoration deco = container.decoration! as BoxDecoration;
    expect(deco.color, PlutusTokens.light.heroSurface);
    expect((deco.border! as Border).top.color, PlutusTokens.light.heroBorder);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/widgets/core/hero_card_test.dart`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Implement `lib/widgets/core/hero_card.dart`**

```dart
import 'package:flutter/material.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/plutus_tokens.dart';

/// The one intentionally rich surface in the app (spec §5): flat navy,
/// 1px gold hairline, figure set in the classical serif. Used for the
/// dashboard net-worth hero; [value] arrives pre-formatted and localized.
class HeroCard extends StatelessWidget {
  final String label;
  final String value;
  final Widget? footer;

  const HeroCard({
    super.key,
    required this.label,
    required this.value,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final PlutusTokens t = context.tokens;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.componentXl),
      decoration: BoxDecoration(
        color: t.heroSurface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: t.heroBorder),
        boxShadow: t.shadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: AppTextStyles.overlineStyle.copyWith(color: t.heroLabel),
          ),
          const SizedBox(height: AppSpacing.componentSm),
          Text(
            value,
            style: AppTextStyles.heroSerifStyle.copyWith(color: t.heroText),
          ),
          if (footer != null) ...<Widget>[
            const SizedBox(height: AppSpacing.componentMd),
            footer!,
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests** — `flutter test test/widgets/core/hero_card_test.dart` → PASS.

- [ ] **Step 5: Commit**

```powershell
git add lib/widgets/core/hero_card.dart test/widgets/core/hero_card_test.dart
git commit -m "feat(core): HeroCard navy/gold-serif hero surface"
```

---

### Task 13: `StatusBadge` + `MetricDelta` primitives

**Files:**
- Create: `lib/widgets/core/status_badge.dart`, `lib/widgets/core/metric_delta.dart`
- Test: `test/widgets/core/status_badge_test.dart` (create)

**Interfaces:**
- Consumes: `StatusColors` quartets from `context.tokens`, `AppTextStyles.captionStyle/numericStyle`.
- Produces:
  - `enum StatusKind { success, warning, info, error }` (in `status_badge.dart`)
  - `class StatusBadge extends StatelessWidget { const StatusBadge({super.key, required this.kind, required this.label}); final StatusKind kind; final String label; }`
  - `class MetricDelta extends StatelessWidget { const MetricDelta({super.key, required this.percent, this.decimals = 1}); final double percent; final int decimals; }` — ▲/▼ + magnitude in success/error text color; caller supplies the sign via `percent`.

- [ ] **Step 1: Write the failing test**

Create `test/widgets/core/status_badge_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/theme/app_theme.dart';
import 'package:plutus_fe_prototype/theme/plutus_tokens.dart';
import 'package:plutus_fe_prototype/widgets/core/metric_delta.dart';
import 'package:plutus_fe_prototype/widgets/core/status_badge.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) {
    return tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: Center(child: child)),
    ));
  }

  testWidgets('StatusBadge pulls the full success quartet',
      (WidgetTester tester) async {
    await pump(tester,
        const StatusBadge(kind: StatusKind.success, label: 'Synced'));
    final Text label = tester.widget<Text>(find.text('Synced'));
    expect(label.style!.color, PlutusTokens.light.success.text);
    final Container pill = tester.widget<Container>(find
        .descendant(
            of: find.byType(StatusBadge), matching: find.byType(Container))
        .first);
    final BoxDecoration deco = pill.decoration! as BoxDecoration;
    expect(deco.color, PlutusTokens.light.success.surface);
    expect((deco.border! as Border).top.color,
        PlutusTokens.light.success.border);
  });

  testWidgets('MetricDelta shows rise in success and fall in error',
      (WidgetTester tester) async {
    await pump(tester, const MetricDelta(percent: 3.2));
    Text txt = tester.widget<Text>(find.text('▲ 3.2%'));
    expect(txt.style!.color, PlutusTokens.light.success.text);

    await pump(tester, const MetricDelta(percent: -1.85, decimals: 2));
    txt = tester.widget<Text>(find.text('▼ 1.85%'));
    expect(txt.style!.color, PlutusTokens.light.error.text);
  });
}
```

- [ ] **Step 2: Run to verify it fails** — `flutter test test/widgets/core/status_badge_test.dart` → FAIL (files missing).

- [ ] **Step 3: Implement `lib/widgets/core/status_badge.dart`**

```dart
import 'package:flutter/material.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/plutus_tokens.dart';

/// The four status families. Rendering always uses the full quartet
/// from [PlutusTokens] — never an ad-hoc red/green.
enum StatusKind { success, warning, info, error }

/// Canonical status indicator (spec §5): pill + filled dot + label,
/// colored by the matching [StatusColors] quartet.
class StatusBadge extends StatelessWidget {
  final StatusKind kind;
  final String label;

  const StatusBadge({super.key, required this.kind, required this.label});

  @override
  Widget build(BuildContext context) {
    final PlutusTokens t = context.tokens;
    final StatusColors s = switch (kind) {
      StatusKind.success => t.success,
      StatusKind.warning => t.warning,
      StatusKind.info => t.info,
      StatusKind.error => t.error,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.componentMd,
        vertical: AppSpacing.componentXs,
      ),
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: AppRadius.borderPill,
        border: Border.all(color: s.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: s.dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.componentSm),
          Text(
            label,
            style: AppTextStyles.captionStyle.copyWith(color: s.text),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Implement `lib/widgets/core/metric_delta.dart`**

```dart
import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/plutus_tokens.dart';

/// Gain/loss indicator (spec §3.4): financial deltas keep the green/red
/// convention via the status quartets — gold is never an up/down signal.
class MetricDelta extends StatelessWidget {
  final double percent;
  final int decimals;

  const MetricDelta({super.key, required this.percent, this.decimals = 1});

  @override
  Widget build(BuildContext context) {
    final PlutusTokens t = context.tokens;
    final bool rising = percent >= 0;
    final Color color = rising ? t.success.text : t.error.text;
    final String arrow = rising ? '\u25B2' : '\u25BC';

    return Text(
      '$arrow ${percent.abs().toStringAsFixed(decimals)}%',
      style: AppTextStyles.numericStyle.copyWith(
        color: color,
        fontSize: AppTextStyles.label,
      ),
    );
  }
}
```

- [ ] **Step 5: Run tests** — `flutter test test/widgets/core/status_badge_test.dart` → PASS.

- [ ] **Step 6: Commit**

```powershell
git add lib/widgets/core/status_badge.dart lib/widgets/core/metric_delta.dart test/widgets/core/status_badge_test.dart
git commit -m "feat(core): StatusBadge quartet pill and MetricDelta gain/loss indicator"
```

---

### Task 14: `MeanderDivider` + `EmptyState` + `AppSkeleton` primitives

**Files:**
- Create: `lib/widgets/core/meander_divider.dart`, `lib/widgets/core/empty_state.dart`, `lib/widgets/core/app_skeleton.dart`
- Test: `test/widgets/core/motif_primitives_test.dart` (create)

**Interfaces:**
- Consumes: `context.tokens`, `AppTextStyles`, `AppSpacing`, `AppMotion.slow`.
- Produces:
  - `class MeanderDivider extends StatelessWidget { const MeanderDivider({super.key, this.height = 10}); final double height; }`
  - `class EmptyState extends StatelessWidget { const EmptyState({super.key, required this.icon, required this.title, this.message, this.actionLabel, this.onAction}); final IconData icon; final String title; final String? message; final String? actionLabel; final VoidCallback? onAction; }` — all copy comes from callers (AppLocalizations lives at the call-site).
  - `class AppSkeleton extends StatefulWidget { const AppSkeleton({super.key, this.width, this.height = 16, this.radius = 6}); }` — neutral pulse, frozen under `MediaQuery.disableAnimations`.

- [ ] **Step 1: Write the failing test**

Create `test/widgets/core/motif_primitives_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/theme/app_theme.dart';
import 'package:plutus_fe_prototype/widgets/core/app_skeleton.dart';
import 'package:plutus_fe_prototype/widgets/core/empty_state.dart';
import 'package:plutus_fe_prototype/widgets/core/meander_divider.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) {
    return tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: Center(child: child)),
    ));
  }

  testWidgets('MeanderDivider paints without errors and spans width',
      (WidgetTester tester) async {
    await pump(tester, const MeanderDivider());
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.getSize(find.byType(MeanderDivider)).height, 10);
  });

  testWidgets('EmptyState shows icon, title, message and one action',
      (WidgetTester tester) async {
    int taps = 0;
    await pump(
        tester,
        EmptyState(
          icon: Icons.savings_outlined,
          title: 'No investments yet',
          message: 'Add your first asset to begin.',
          actionLabel: 'Add investment',
          onAction: () => taps++,
        ));
    expect(find.byIcon(Icons.savings_outlined), findsOneWidget);
    expect(find.text('No investments yet'), findsOneWidget);
    expect(find.text('Add your first asset to begin.'), findsOneWidget);
    await tester.tap(find.text('Add investment'));
    expect(taps, 1);
  });

  testWidgets('AppSkeleton pulses, and freezes under disableAnimations',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Scaffold(body: AppSkeleton(width: 120)),
      ),
    ));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.hasRunningAnimations, isFalse);
  });
}
```

- [ ] **Step 2: Run to verify it fails** — `flutter test test/widgets/core/motif_primitives_test.dart` → FAIL (files missing).

- [ ] **Step 3: Implement `lib/widgets/core/meander_divider.dart`**

```dart
import 'package:flutter/material.dart';
import '../../theme/plutus_tokens.dart';

/// Greek-key (meander) hairline divider (spec §6). At arm's length it
/// reads as a divider; up close, the motif. One unit is picked out in
/// gold so the detail is discoverable, never loud.
class MeanderDivider extends StatelessWidget {
  final double height;

  const MeanderDivider({super.key, this.height = 10});

  @override
  Widget build(BuildContext context) {
    final PlutusTokens t = context.tokens;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _MeanderPainter(
          lineColor: t.border,
          accentColor: t.gold.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

class _MeanderPainter extends CustomPainter {
  final Color lineColor;
  final Color accentColor;

  const _MeanderPainter({required this.lineColor, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    const double unit = 14;
    final double y0 = size.height;
    final int units = (size.width / unit).floor();
    if (units < 1) return;
    // Center the pattern; pick the gold unit just left of center.
    final double startX = (size.width - units * unit) / 2;
    final int goldIndex = (units / 2).floor() - 1;

    for (int i = 0; i < units; i++) {
      final double x = startX + i * unit;
      final Paint paint = Paint()
        ..color = i == goldIndex ? accentColor : lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      final Path p = Path()
        ..moveTo(x, y0)
        ..lineTo(x, 0)
        ..lineTo(x + unit * 0.55, 0)
        ..lineTo(x + unit * 0.55, y0 * 0.55)
        ..lineTo(x + unit * 0.25, y0 * 0.55)
        ..moveTo(x + unit * 0.55, 0)
        ..lineTo(x + unit, 0)
        ..lineTo(x + unit, y0);
      canvas.drawPath(p, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MeanderPainter old) =>
      old.lineColor != lineColor || old.accentColor != accentColor;
}
```

- [ ] **Step 4: Implement `lib/widgets/core/empty_state.dart`**

```dart
import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/plutus_tokens.dart';

/// Calm empty state (spec §5): muted icon, title, optional caption, and
/// at most one gold CTA. Copy is passed in by the caller (localized at
/// the call-site via AppLocalizations).
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final PlutusTokens t = context.tokens;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.layoutMd),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 40, color: t.textMuted),
            const SizedBox(height: AppSpacing.componentLg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleStyle.copyWith(color: t.text),
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: AppSpacing.componentSm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyStyle.copyWith(color: t.textSecondary),
              ),
            ],
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: AppSpacing.componentXl),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Implement `lib/widgets/core/app_skeleton.dart`**

```dart
import 'package:flutter/material.dart';
import '../../theme/app_elevation.dart';
import '../../theme/plutus_tokens.dart';

/// Neutral loading placeholder (spec §5): a surfaceSubtle slab pulsing
/// gently. Honors reduced motion — under
/// `MediaQuery.disableAnimations` it renders static.
class AppSkeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;

  const AppSkeleton({super.key, this.width, this.height = 16, this.radius = 6});

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.slow * 2,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduced = MediaQuery.of(context).disableAnimations;
    if (reduced) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PlutusTokens t = context.tokens;
    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.55).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: t.surfaceSubtle,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Run tests** — `flutter test test/widgets/core/motif_primitives_test.dart` → PASS. Then `flutter test` (full) → PASS.

- [ ] **Step 7: Commit**

```powershell
git add lib/widgets/core/meander_divider.dart lib/widgets/core/empty_state.dart lib/widgets/core/app_skeleton.dart test/widgets/core/motif_primitives_test.dart
git commit -m "feat(core): MeanderDivider, EmptyState and AppSkeleton primitives"
```

---

### Task 15: Full verification sweep

**Files:** none (verification only)

**Interfaces:** consumes everything above; produces the PR-readiness evidence.

- [ ] **Step 1: Static analysis**

```powershell
flutter analyze
```

Expected: no errors outside the known `packages/dashboard/example` baseline. Record the exact issue counts for the PR description.

- [ ] **Step 2: Full test suite**

```powershell
flutter test
```

Expected: all green.

- [ ] **Step 3: Web release build (canonical amplify flags)**

```powershell
flutter build web --release --no-tree-shake-icons --source-maps --dart-define=FLUTTER_WEB_AUTO_DETECT=true --dart-define-from-file=app.env
```

Expected: build succeeds; `build/web/assets/fonts/` (or the asset manifest) contains the five bundled TTFs.

- [ ] **Step 4: Visual smoke — both themes, desktop + mobile widths**

Run `flutter run -d chrome --dart-define-from-file=app.env`, then with Playwright (or manually) capture: login screen and dashboard, light and dark, at 1280px and 390px widths. Checklist:
- No magenta/pink/violet remnants anywhere.
- Gold appears only on: CTAs, nav indicator, selected chips/tabs, focus borders.
- Body text legible on every surface in both themes.
- Bundled Inter is rendering (compare a numeral's shape against system font — Inter's "1" has a flat serif foot).

Fix anything broken before proceeding; re-run affected tests.

- [ ] **Step 5: Commit any fixes**

```powershell
git add <specific files changed during fixes>
git commit -m "fix(theme): visual smoke fixes from verification sweep"
```

(Skip if nothing changed.)

---

### Task 16: Push branch + open PR

**Files:** none

- [ ] **Step 1: Push**

```powershell
git push -u origin feat/gold-navy-tokens
```

- [ ] **Step 2: Open the PR**

```powershell
gh pr create --base main --title "feat(theme): gold/navy token foundation (redesign PR1)" --body @'
## Summary
PR1 of 4 for the gold/navy redesign (spec: docs/superpowers/specs/2026-07-29-gold-navy-redesign-design.md).

- New `PlutusTokens` ThemeExtension (`context.tokens`) with full light/dark gold/navy palette, status quartets, chart palettes, and neutral elevation
- Legacy `AppColors`/`AppElevation`/`AppGradients` revalued to the new palette and `@Deprecated` (deleted in PR4) — the whole app re-tints via the shims
- Bundled Inter (400-700) + Cormorant Garamond 600; calm type roles + `overline`/`heroSerif`
- Rebuilt ThemeData: gold CTA buttons w/ navy ink, hairline inputs w/ gold focus, goldWeak nav indicator, calm chrome
- Core primitives for PR2/3: `AppCard`, `AppCanvas`, `HeroCard`, `StatusBadge`, `MetricDelta`, `MeanderDivider`, `EmptyState`, `AppSkeleton`
- WCAG AA contrast enforced by `test/theme/contrast_test.dart`

## Verification
- `flutter analyze` — no new issues over baseline
- `flutter test` — green
- `flutter build web` (amplify.yml flags) — succeeds
- Visual smoke: login + dashboard, light/dark, 1280px/390px

## Next
PR2: nav chrome + dashboard + dashboard package migration to `context.tokens`.
'@
```

- [ ] **Step 3: Report** — the command prints the PR URL; paste it back to the user.

---

## Plan self-review record

- **Spec coverage (PR1 scope = spec §2, §3, §4, §5-primitives, §9, §10-row-1):** tokens+lerp (Task 2), contrast gate (Task 3), dual spacing + radius (Task 4), shim revalue (Tasks 5-6), typography (Tasks 1, 7), ThemeData + ColorScheme + component themes (Tasks 8-10), all eight primitives (Tasks 11-14), verification gates (Task 15), branch/PR (Task 16). Spec items deliberately NOT in PR1: screen migrations, nav lockup, dashboard package, web shell, motif placement, localized tagline — those are PR2-4 per spec §10.
- **Placeholder scan:** no TBDs; every code step contains complete code; the two contingencies (Inter zip layout, Cormorant static-vs-variable) specify exact fallback commands.
- **Type consistency:** `context.tokens` / `PlutusTokens` field names match across Tasks 2, 3, 8-14; `StatusKind`/`StatusColors` names match Tasks 2 and 13; `AppRadius.button/sheet` introduced in Task 4 and consumed in Tasks 9-10; `overlineStyle`/`heroSerifStyle` introduced in Task 7 and consumed in Task 12.
- **Known deviations (documented inline):** light `textMuted` nudged `#8A93AB`→`#7E88A3` (AA floor); input focus halo deferred to the form-field wrapper in PR2/3 (not expressible in `InputDecorationTheme`).
