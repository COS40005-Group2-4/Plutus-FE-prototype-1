import 'package:flutter/material.dart';

/// Reusable brand gradients. Single source of truth so screens never
/// hand-roll their own gradient stops.
@Deprecated('Transitional shim — use context.tokens (PlutusTokens). Removed in PR4.')
class AppGradients {
  AppGradients._();

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

  /// Returns the brand-appropriate hero balance gradient.
  static LinearGradient balanceCard(Brightness b) =>
      b == Brightness.dark ? balanceCardDark : balanceCardLight;

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
}
