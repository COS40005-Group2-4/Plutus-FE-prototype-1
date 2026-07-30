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
      chartCategorical: <Color>[
        for (int i = 0; i < chartCategorical.length; i++)
          Color.lerp(chartCategorical[i], other.chartCategorical[i], t)!,
      ],
      heatmapRamp: <Color>[
        for (int i = 0; i < heatmapRamp.length; i++)
          Color.lerp(heatmapRamp[i], other.heatmapRamp[i], t)!,
      ],
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
