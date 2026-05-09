import 'package:flutter/material.dart';

/// Material 3 type scale for the Plutus app.
///
/// All sizes follow the M3 spec so [Theme.of(context).textTheme] returns
/// consistent results across screens. Use the role names below directly,
/// or pull from the [TextTheme] (e.g. `theme.textTheme.titleMedium`).
///
///   display  L 57 / M 45 / S 36   hero numbers, splash
///   headline L 32 / M 28 / S 24   page titles
///   title    L 22 / M 16 / S 14   section / card headings
///   body     L 16 / M 14 / S 12   readable text
///   label    L 14 / M 12 / S 11   buttons, badges, captions
class AppTextStyles {
  AppTextStyles._();

  // ── Font sizes (M3 spec) ──
  static const double displayLarge = 57;
  static const double displayMedium = 45;
  static const double displaySmall = 36;

  static const double headlineLarge = 32;
  static const double headlineMedium = 28;
  static const double headlineSmall = 24;

  static const double titleLarge = 22;
  static const double titleMedium = 16;
  static const double titleSmall = 14;

  static const double bodyLarge = 16;
  static const double bodyMedium = 14;
  static const double bodySmall = 12;

  static const double labelLargeSize = 14;
  static const double labelMediumSize = 12;
  static const double labelSmallSize = 11;

  // ── Legacy aliases used by dashboard widgets and existing callers.
  // Tuned for confident on-card readability over the muted accent fills.
  static const double display = 44;
  static const double heading = 30;
  static const double title = 22;
  static const double subtitle = 18;
  static const double body = 15;
  static const double label = 13;
  static const double caption = 12;

  // Default font family. Use a system-friendly stack;
  // Flutter falls back gracefully when Inter is unavailable.
  static const String fontFamily = 'Inter';
  static const List<String> fontFamilyFallback = <String>[
    '-apple-system',
    'BlinkMacSystemFont',
    'SF Pro Text',
    'Segoe UI',
    'Roboto',
  ];

  // ── M3 TextStyle objects (no color — that comes from the theme) ──
  static const TextStyle _base = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
  );

  static final TextStyle displayLargeStyle = _base.copyWith(
    fontSize: displayLarge,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.4,
    height: 1.05,
  );
  static final TextStyle displayMediumStyle = _base.copyWith(
    fontSize: displayMedium,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    height: 1.1,
  );
  static final TextStyle displaySmallStyle = _base.copyWith(
    fontSize: displaySmall,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    height: 1.15,
  );

  static final TextStyle headlineLargeStyle = _base.copyWith(
    fontSize: headlineLarge,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 1.2,
  );
  static final TextStyle headlineMediumStyle = _base.copyWith(
    fontSize: headlineMedium,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.25,
  );
  static final TextStyle headlineSmallStyle = _base.copyWith(
    fontSize: headlineSmall,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static final TextStyle titleLargeStyle = _base.copyWith(
    fontSize: titleLarge,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.3,
  );
  static final TextStyle titleMediumStyle = _base.copyWith(
    fontSize: titleMedium,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
  );
  static final TextStyle titleSmallStyle = _base.copyWith(
    fontSize: titleSmall,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static final TextStyle bodyLargeStyle = _base.copyWith(
    fontSize: bodyLarge,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    height: 1.5,
  );
  static final TextStyle bodyMediumStyle = _base.copyWith(
    fontSize: bodyMedium,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.45,
  );
  static final TextStyle bodySmallStyle = _base.copyWith(
    fontSize: bodySmall,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.3,
    height: 1.4,
  );

  static final TextStyle labelLargeStyle = _base.copyWith(
    fontSize: labelLargeSize,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.4,
  );
  static final TextStyle labelMediumStyle = _base.copyWith(
    fontSize: labelMediumSize,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    height: 1.3,
  );
  static final TextStyle labelSmallStyle = _base.copyWith(
    fontSize: labelSmallSize,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.3,
  );

  // ── Legacy alias styles used by dashboard widgets.
  // Confident weights and explicit sizes so card content reads strongly
  // over the muted accent fills.
  static final TextStyle displayStyle = _base.copyWith(
    fontSize: display,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.2,
    height: 1.05,
  );
  static final TextStyle headingStyle = _base.copyWith(
    fontSize: heading,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.15,
  );
  static final TextStyle titleStyle = _base.copyWith(
    fontSize: title,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.25,
  );
  static final TextStyle subtitleStyle = _base.copyWith(
    fontSize: subtitle,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    height: 1.3,
  );
  static final TextStyle bodyStyle = _base.copyWith(
    fontSize: body,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.05,
    height: 1.45,
  );
  static final TextStyle bodyStrongStyle = _base.copyWith(
    fontSize: body,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.05,
    height: 1.4,
  );
  static final TextStyle labelStyle = _base.copyWith(
    fontSize: label,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    height: 1.3,
  );
  static final TextStyle captionStyle = _base.copyWith(
    fontSize: caption,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    height: 1.3,
  );

  /// Tabular figures for currency/numeric columns.
  /// Bold by default — finance numbers are headline content, not body text.
  static final TextStyle numericStyle = _base.copyWith(
    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.15,
  );

  /// Two-tone TextSpan helper for headlines like "income has increased!"
  /// where the trailing word is rendered in [accentColor]. Returns a single
  /// [TextSpan] that can be passed to [Text.rich].
  ///
  /// Pass [base] to control the base style (defaults to [headingStyle]).
  static TextSpan twoTone({
    required String prefix,
    required String accent,
    required Color baseColor,
    required Color accentColor,
    TextStyle? base,
    String separator = ' ',
  }) {
    final TextStyle baseStyle = (base ?? headingStyle).copyWith(color: baseColor);
    return TextSpan(
      style: baseStyle,
      children: <TextSpan>[
        TextSpan(text: prefix),
        TextSpan(text: separator),
        TextSpan(
          text: accent,
          style: baseStyle.copyWith(color: accentColor),
        ),
      ],
    );
  }
}
