import 'package:flutter/material.dart';

/// Semantic color tokens for the Plutus app using a gold/navy design system.
///
/// Light theme — warm gold accents on a clean white/blue-gray canvas with
/// navy text and subtle shadows.
/// Dark theme — soft gold accents on a deep navy canvas with light blue-gray
/// text and elevated surfaces.
/// This class is a transitional shim over PlutusTokens — callers resolve
/// colors via AppColors.* (alias) rather than directly.
class AppColors {
  AppColors._();

  // ── Brand ──
  static const primary = Color(0xFFC9970F);          // gold-500
  static const primaryStrong = Color(0xFFA67A0B);    // gold-600
  static const primarySoft = Color(0xFFFDF9EC);      // gold-50

  static const primaryDark = Color(0xFFE0B32F);      // gold-400
  static const primaryStrongDark = Color(0xFFECCB5F); // gold-300
  static const primarySoftDark = Color(0x1FE0B32F);   // gold-400 @12%

  /// Gold accent for chips/badges in light mode.
  /// Used as ColorScheme.secondary in light themes.
  static const accent = Color(0xFFFAF0CE);           // gold-100
  /// Gold-300 accent for chips/badges in dark mode.
  static const accentDark = Color(0xFFECCB5F);      // gold-300

  // ── CTA pill button ──
  static const ctaButtonLight = Color(0xFFC9970F);  // gold-500
  static const ctaButtonDark = Color(0xFFE0B32F);   // gold-400

  // ── Neutral surfaces (light) ──
  static const backgroundLight = Color(0xFFF7F8FA);
  static const surfaceLight = Color(0xFFFFFFFF);     // raised card
  static const surfaceMutedLight = Color(0xFFF1F3F6);
  static const surfaceElevatedLight = Color(0xFFFFFFFF);
  static const borderLight = Color(0xFFE5E8EE);
  static const dividerLight = Color(0xFFE5E8EE);

  // ── Neutral surfaces (dark) ──
  static const backgroundDark = Color(0xFF0C1120);
  static const surfaceDark = Color(0xFF131A2E);
  static const surfaceMidDark = Color(0xFF1A2340);
  static const surfaceElevatedDark = Color(0xFF1A2340);
  static const borderDark = Color(0xFF232D4A);
  static const dividerDark = Color(0xFF232D4A);

  // ── Legacy aliases (kept for backwards compatibility) ──
  // ignore: deprecated_member_use_from_same_package
  static const backgroundLightStart = backgroundLight;
  // ignore: deprecated_member_use_from_same_package
  static const backgroundLightEnd = backgroundLight;
  static const menuBackground = surfaceDark;

  // ── Text (light) ──
  static const textOnLight = Color(0xFF131C3D);      // navy-900
  static const textOnLightSecondary = Color(0xFF4A5573);
  static const textOnLightTertiary = Color(0xFF7E88A3);

  // ── Text (dark) ──
  static const textOnDark = Color(0xFFEDF0F7);
  static const textOnDarkSecondary = Color(0xFFAAB4CE);
  static const textOnDarkTertiary = Color(0xFF6E7A99);

  // ── Semantic ──
  static const error = Color(0xFFD92D20);
  static const success = Color(0xFF079455);
  static const warning = Color(0xFFDC6803);
  static const info = Color(0xFF52659A);

  // ── Chart palette (default = light theme) ──
  static const List<Color> chartPalette = chartPaletteLight;

  static const List<Color> chartPaletteLight = <Color>[
    Color(0xFF24346A),
    Color(0xFFC9970F),
    Color(0xFF8093BC),
    Color(0xFF35726E),
    Color(0xFF6E4E7E),
    Color(0xFF8A93AB),
  ];

  static const List<Color> chartPaletteDark = <Color>[
    Color(0xFFB3BFDB),
    Color(0xFFE0B32F),
    Color(0xFF8093BC),
    Color(0xFF5FA39E),
    Color(0xFFA886B8),
    Color(0xFF6E7A99),
  ];

  // ── Widget accent colors (sidebar registry) ──
  // Harmonized with the gold/navy palette so colored widget cards read
  // as siblings, not strangers. Saturation kept low so card text stays
  // legible without heavy tints.
  static const profileAccent = Color(0xFF52659A);
  static const budgetAccent = Color(0xFF33457D);
  static const categoryBudgetAccent = Color(0xFF52659A);
  static const historyAccent = Color(0xFF33457D);
  static const cashflowAccent = Color(0xFF24346A);
  static const expenseAccent = Color(0xFFD92D20);
  static const incomeAccent = Color(0xFF079455);
  static const savingsAccent = Color(0xFFC9970F);
  static const netWorthAccent = Color(0xFFC9970F);
  static const heatmapAccent = Color(0xFFC9970F);
  static const marketAccent = Color(0xFF52659A);
  static const billsAccent = Color(0xFF33457D);
  static const taxAccent = Color(0xFF52659A);
  static const importAccent = Color(0xFF52659A);
  static const exportAccent = Color(0xFF33457D);

  // ── Adaptive accessors ──
  static Color background(Brightness b) =>
      b == Brightness.dark ? backgroundDark : backgroundLight;

  static Color surface(Brightness b) =>
      b == Brightness.dark ? surfaceDark : surfaceLight;

  static Color surfaceMuted(Brightness b) =>
      b == Brightness.dark ? surfaceMidDark : surfaceMutedLight;

  static Color surfaceElevated(Brightness b) =>
      b == Brightness.dark ? surfaceElevatedDark : surfaceElevatedLight;

  static Color border(Brightness b) =>
      b == Brightness.dark ? borderDark : borderLight;

  static Color divider(Brightness b) =>
      b == Brightness.dark ? dividerDark : dividerLight;

  static Color textPrimary(Brightness b) =>
      b == Brightness.dark ? textOnDark : textOnLight;

  static Color textSecondary(Brightness b) =>
      b == Brightness.dark ? textOnDarkSecondary : textOnLightSecondary;

  static Color textTertiary(Brightness b) =>
      b == Brightness.dark ? textOnDarkTertiary : textOnLightTertiary;

  static Color brand(Brightness b) =>
      b == Brightness.dark ? primaryDark : primary;

  static Color brandStrong(Brightness b) =>
      b == Brightness.dark ? primaryStrongDark : primaryStrong;

  static Color brandSoft(Brightness b) =>
      b == Brightness.dark ? primarySoftDark : primarySoft;

  static Color accentColor(Brightness b) =>
      b == Brightness.dark ? accentDark : accent;

  /// Background for the primary pill CTA. In dark mode prefer using
  /// AppGradients.ctaButton for the gradient version.
  static Color ctaButtonBackground(Brightness b) =>
      b == Brightness.dark ? ctaButtonDark : ctaButtonLight;

  static Color ctaButtonForeground(Brightness b) => const Color(0xFF0C122A);

  static List<Color> chartPaletteFor(Brightness b) =>
      b == Brightness.dark ? chartPaletteDark : chartPaletteLight;

  static Color gridLine(Brightness b) => b == Brightness.dark
      ? Colors.white.withValues(alpha: 0.06)
      : const Color(0xFF131C3D).withValues(alpha: 0.06);

  static Color borderLine(Brightness b) => b == Brightness.dark
      ? Colors.white.withValues(alpha: 0.10)
      : const Color(0xFF131C3D).withValues(alpha: 0.10);

  // ── On-accent foreground (dashboard widget cards) ──
  //
  // Dashboard widget cards render as `GlassContainer(color: accent,
  // opacity: 0.2)` — i.e. a 20% accent tint blended over the active
  // theme's surface. The resulting card is a light pastel in light mode
  // and a slightly accented dark navy in dark mode.
  //
  // The on-accent helpers below pick a foreground that clears WCAG-AA
  // (4.5:1) against that *resolved* card surface, regardless of which
  // accent the widget uses. They replace ad-hoc `Colors.white` /
  // `AppColors.textOnDark` reads inside dashboard widgets.

  /// Effective rendered card surface for [accent] given the global
  /// [brightness]. Mirrors `GlassContainer`'s standard blend behavior
  /// at opacity 0.2 — kept on `AppColors` as the single source of truth
  /// so the contrast self-check can exercise the same math.
  static Color cardSurfaceForAccent(Color accent, Brightness brightness) {
    final base = surface(brightness);
    return Color.alphaBlend(accent.withValues(alpha: 0.2), base);
  }

  /// Returns the appropriate foreground "ink" for an accent card. Picks
  /// dark on light pastel surfaces and light on dark navy-tinted ones,
  /// using relative luminance — accent-agnostic by design so the call
  /// sites stay mechanical.
  static Color _onAccentInk(Color accent, Brightness brightness) {
    return cardSurfaceForAccent(accent, brightness).computeLuminance() > 0.5
        ? textOnLight
        : textOnDark;
  }

  /// Primary on-accent text — body and headline tone. WCAG-AA against
  /// the resolved card surface.
  static Color onAccentPrimary(Color accent, Brightness brightness) =>
      _onAccentInk(accent, brightness);

  /// Secondary on-accent text — subtitle / caption tone. Still > 4.5:1
  /// because the underlying ink is pure black/white.
  static Color onAccentSecondary(Color accent, Brightness brightness) =>
      _onAccentInk(accent, brightness).withValues(alpha: 0.78);

  /// Tertiary on-accent text — eyebrow labels (BUDGETED / SPENT / NAME),
  /// helper copy. ~3:1, distinctly lower-emphasis but still legible.
  static Color onAccentTertiary(Color accent, Brightness brightness) =>
      _onAccentInk(accent, brightness).withValues(alpha: 0.62);

  /// Idle header-icon tone for an accent card (~3:1 against surface).
  static Color iconOnAccent(Color accent, Brightness brightness) =>
      _onAccentInk(accent, brightness).withValues(alpha: 0.78);

  /// Pressed / hovered header-icon tone — the full primary ink.
  static Color iconOnAccentEmphasis(Color accent, Brightness brightness) =>
      _onAccentInk(accent, brightness);

  /// Hairline divider tone for accent cards. Pulled from the on-accent
  /// ink so it sits visibly above the pastel surface without imitating
  /// the global divider token, which is tuned for neutral surfaces.
  static Color dividerOnAccent(Color accent, Brightness brightness) =>
      _onAccentInk(accent, brightness).withValues(alpha: 0.15);

  /// Track tone for progress bars on accent cards (semantic fills keep
  /// their own color).
  static Color progressTrackOnAccent(Color accent, Brightness brightness) =>
      _onAccentInk(accent, brightness).withValues(alpha: 0.15);

  /// Public registry of accent colors used by dashboard widget cards.
  /// Iterated by the contrast self-check; keep in sync with the per-
  /// widget accent constants above.
  static const List<Color> dashboardAccents = <Color>[
    profileAccent,
    budgetAccent,
    categoryBudgetAccent,
    historyAccent,
    cashflowAccent,
    expenseAccent,
    incomeAccent,
    savingsAccent,
    netWorthAccent,
    heatmapAccent,
    marketAccent,
    billsAccent,
    taxAccent,
    importAccent,
    exportAccent,
  ];

  // ── Edit mode (dashboard) ──
  // Editing the dashboard layout reads as an intentional surface, not a
  // warning. The edit accent reuses the brand family on both themes so
  // the dashed outline, snap glow, and banner all feel native.
  static Color editAccent(Brightness b) => brand(b);

  /// Faint overlay used on the dashed widget outline in edit mode.
  /// Accent at low alpha — keeps the outline readable on every surface.
  static Color editOutline(Brightness b) =>
      brand(b).withValues(alpha: b == Brightness.dark ? 0.55 : 0.45);

  /// Background fill for the in-flight snap target glow.
  static Color editSnapGlow(Brightness b) =>
      brand(b).withValues(alpha: b == Brightness.dark ? 0.22 : 0.16);

  /// Chip fill behind a resize handle. Solid on light, slightly translucent
  /// on dark so the handle reads above the gold halo.
  static Color editHandleFill(Brightness b) =>
      b == Brightness.dark ? primaryDark : primary;

  /// Foreground (icon / dot) color rendered inside an [editHandleFill] chip.
  static Color editHandleForeground(Brightness b) => Colors.white;

  // ── Theme-adaptive semantic colors for data display ──
  static const _positiveLight = Color(0xFF067647);
  static const _positiveDark = Color(0xFF3CCF8E);
  static const _negativeLight = Color(0xFFB42318);
  static const _negativeDark = Color(0xFFF49A92);

  static Color positive(Brightness b) =>
      b == Brightness.dark ? _positiveDark : _positiveLight;

  static Color negative(Brightness b) =>
      b == Brightness.dark ? _negativeDark : _negativeLight;
}
