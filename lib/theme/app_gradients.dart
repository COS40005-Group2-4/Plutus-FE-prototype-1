import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Reusable brand gradients. Single source of truth so screens never
/// hand-roll their own gradient stops.
class AppGradients {
  AppGradients._();

  /// Hero balance card gradient (dark mode).
  /// 135deg from violet-400 → violet-600.
  static const LinearGradient balanceCardDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      AppColors.primaryDark,            // violet-400 #A78BFA
      Color(0xFF6D5BD0),                // violet-600
    ],
  );

  /// Hero balance card gradient (light mode).
  /// Magenta-300 → magenta-500 for the soft warm hero.
  static const LinearGradient balanceCardLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFFF9A8D4), // pink-300
      AppColors.primary, // magenta-500
    ],
  );

  /// Returns the brand-appropriate hero balance gradient.
  static LinearGradient balanceCard(Brightness b) =>
      b == Brightness.dark ? balanceCardDark : balanceCardLight;

  /// Hero background wash for the dark mode canvas.
  static const LinearGradient heroBackgroundDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      Color(0xFF1B1F4A),
      AppColors.backgroundDark,
    ],
  );

  /// CTA pill gradient (dark mode). 135deg violet-400 → violet-600.
  static const LinearGradient ctaButtonDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      AppColors.primaryDark,
      Color(0xFF6D5BD0),
    ],
  );
}
