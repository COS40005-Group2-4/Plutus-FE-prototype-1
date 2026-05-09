import 'package:flutter/material.dart';

/// Semantic color tokens for the Plutus app.
///
/// Light theme — friendly fintech magenta on a soft pink canvas, with a
/// near-black pill CTA and sunshine-yellow accent chips.
/// Dark theme — premium violet on a deep navy canvas with violet gradient
/// hero cards.
class AppColors {
  AppColors._();

  // ── Brand ──
  static const primary = Color(0xFFEC4899);          // magenta-500 (light)
  static const primaryStrong = Color(0xFFDB2777);    // magenta-600 (light pressed)
  static const primarySoft = Color(0xFFFCE7F3);      // magenta-100 (light tinted surfaces)

  static const primaryDark = Color(0xFFA78BFA);      // violet-400 (dark)
  static const primaryStrongDark = Color(0xFF8B5CF6); // violet-500 (dark pressed)
  static const primarySoftDark = Color(0xFF2A2360);   // violet-900 tint (dark tinted surfaces)

  /// Sunshine yellow accent for chips/badges in light mode.
  /// Used as ColorScheme.secondary in light themes.
  static const accent = Color(0xFFFFE66D);
  /// Violet-300 accent for chips/badges in dark mode.
  static const accentDark = Color(0xFFC4B5FD);

  // ── CTA pill button ──
  static const ctaButtonLight = Color(0xFF0E0712);   // near-black pill (light)
  static const ctaButtonDark = Color(0xFF8B5CF6);    // violet-500 (dark – use AppGradients.cta in widgets)

  // ── Neutral surfaces (light) ──
  static const backgroundLight = Color(0xFFFDF2F8);  // very pale pink canvas
  static const surfaceLight = Color(0xFFFFFFFF);     // raised card
  static const surfaceMutedLight = Color(0xFFFBE8F1); // search field, muted card
  static const surfaceElevatedLight = Color(0xFFFFFFFF);
  static const borderLight = Color(0xFFF4D4E3);
  static const dividerLight = Color(0xFFF7E1EC);

  // ── Neutral surfaces (dark) ──
  static const backgroundDark = Color(0xFF0B0E2A);   // deep navy canvas
  static const surfaceDark = Color(0xFF141838);      // raised card
  static const surfaceMidDark = Color(0xFF1B2046);   // muted card / input
  static const surfaceElevatedDark = Color(0xFF222853); // overlay / nav
  static const borderDark = Color(0xFF2A2F5C);
  static const dividerDark = Color(0xFF1E2348);

  // ── Legacy aliases (kept for backwards compatibility) ──
  // ignore: deprecated_member_use_from_same_package
  static const backgroundLightStart = backgroundLight;
  // ignore: deprecated_member_use_from_same_package
  static const backgroundLightEnd = backgroundLight;
  static const menuBackground = surfaceDark;

  // ── Text (light) ──
  static const textOnLight = Color(0xFF1A1224);
  static const textOnLightSecondary = Color(0xFF6B5B72);
  static const textOnLightTertiary = Color(0xFF9A8AA0);

  // ── Text (dark) ──
  static const textOnDark = Color(0xFFFFFFFF);
  static const textOnDarkSecondary = Color(0xFFC7C9E0);
  static const textOnDarkTertiary = Color(0xFF8C8FB5);

  // ── Semantic ──
  static const error = Color(0xFFE11D48);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);

  // ── Chart palette (default = light theme) ──
  static const List<Color> chartPalette = chartPaletteLight;

  static const List<Color> chartPaletteLight = <Color>[
    Color(0xFFEC4899), // magenta
    Color(0xFFFFE66D), // sunshine yellow
    Color(0xFFF472B6), // pink-300
    Color(0xFFA855F7), // violet-500
    Color(0xFFFB7185), // rose-400
    Color(0xFFF59E0B), // amber
    Color(0xFF22D3EE), // cyan
    Color(0xFF10B981), // emerald
  ];

  static const List<Color> chartPaletteDark = <Color>[
    Color(0xFFA78BFA), // violet-400
    Color(0xFFC4B5FD), // violet-300
    Color(0xFFF472B6), // pink-300
    Color(0xFF22D3EE), // cyan
    Color(0xFF34D399), // emerald-400
    Color(0xFFFBBF24), // amber-400
    Color(0xFF60A5FA), // blue-400
    Color(0xFFF87171), // red-400
  ];

  // ── Widget accent colors (sidebar registry) ──
  // Harmonized with the magenta/violet palette so colored widget cards read
  // as siblings, not strangers. Saturation kept low so card text stays
  // legible without heavy tints.
  static const profileAccent = Color(0xFF8B5CF6);          // violet
  static const budgetAccent = Color(0xFFEC4899);           // magenta
  static const categoryBudgetAccent = Color(0xFFF472B6);   // pink-300
  static const historyAccent = Color(0xFF10B981);          // emerald
  static const cashflowAccent = Color(0xFF6366F1);         // indigo
  static const expenseAccent = Color(0xFFE11D48);          // rose
  static const incomeAccent = Color(0xFF10B981);           // emerald
  static const savingsAccent = Color(0xFFF59E0B);          // amber
  static const netWorthAccent = Color(0xFF22D3EE);         // cyan
  static const heatmapAccent = Color(0xFFA78BFA);          // violet-400
  static const marketAccent = Color(0xFFEC4899);           // magenta
  static const billsAccent = Color(0xFFFB7185);            // rose-400
  static const taxAccent = Color(0xFF6366F1);              // indigo
  static const importAccent = Color(0xFFF59E0B);           // amber
  static const exportAccent = Color(0xFFA855F7);           // violet-500

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

  static Color ctaButtonForeground(Brightness b) => Colors.white;

  static List<Color> chartPaletteFor(Brightness b) =>
      b == Brightness.dark ? chartPaletteDark : chartPaletteLight;

  static Color gridLine(Brightness b) => b == Brightness.dark
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.black.withValues(alpha: 0.05);

  static Color borderLine(Brightness b) => b == Brightness.dark
      ? Colors.white.withValues(alpha: 0.10)
      : Colors.black.withValues(alpha: 0.08);

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
  /// on dark so the handle reads above the violet glow halo.
  static Color editHandleFill(Brightness b) =>
      b == Brightness.dark ? primaryDark : primary;

  /// Foreground (icon / dot) color rendered inside an [editHandleFill] chip.
  static Color editHandleForeground(Brightness b) => Colors.white;

  // ── Theme-adaptive semantic colors for data display ──
  static const _positiveLight = Color(0xFF10B981);
  static const _positiveDark = Color(0xFF34D399);
  static const _negativeLight = Color(0xFFE11D48);
  static const _negativeDark = Color(0xFFF87171);

  static Color positive(Brightness b) =>
      b == Brightness.dark ? _positiveDark : _positiveLight;

  static Color negative(Brightness b) =>
      b == Brightness.dark ? _negativeDark : _negativeLight;
}
