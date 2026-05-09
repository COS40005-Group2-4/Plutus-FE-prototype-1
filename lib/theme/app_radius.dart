import 'package:flutter/material.dart';

/// Standardized corner radius scale.
///
/// Existing tokens (xs..xl) are kept for backwards compatibility; the
/// new design system adds component-named tokens used by the redesigned
/// theme (pill, card, surface, input, iconButton).
class AppRadius {
  AppRadius._();

  // ── Generic scale ──
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  // ── Component-named tokens ──
  /// Fully-rounded pill (e.g. primary CTA, chips).
  static const double pill = 999;
  /// Card radius (`Card`, list cards, balance card).
  static const double card = 24;
  /// Surface / sheet radius (bottom sheets, dialogs).
  static const double surface = 28;
  /// Input field radius.
  static const double input = 16;
  /// Small icon-button radius.
  static const double iconButton = 14;

  static BorderRadius borderXs = BorderRadius.circular(xs);
  static BorderRadius borderSm = BorderRadius.circular(sm);
  static BorderRadius borderMd = BorderRadius.circular(md);
  static BorderRadius borderLg = BorderRadius.circular(lg);
  static BorderRadius borderXl = BorderRadius.circular(xl);

  static BorderRadius borderPill = BorderRadius.circular(pill);
  static BorderRadius borderCard = BorderRadius.circular(card);
  static BorderRadius borderSurface = BorderRadius.circular(surface);
  static BorderRadius borderInput = BorderRadius.circular(input);
  static BorderRadius borderIconButton = BorderRadius.circular(iconButton);
}
