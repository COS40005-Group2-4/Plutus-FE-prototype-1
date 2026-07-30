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

  static BorderRadius borderXs = BorderRadius.circular(xs);
  static BorderRadius borderSm = BorderRadius.circular(sm);
  static BorderRadius borderMd = BorderRadius.circular(md);
  static BorderRadius borderLg = BorderRadius.circular(lg);
  static BorderRadius borderXl = BorderRadius.circular(xl);

  static BorderRadius borderPill = BorderRadius.circular(pill);
  static BorderRadius borderButton = BorderRadius.circular(button);
  static BorderRadius borderCard = BorderRadius.circular(card);
  static BorderRadius borderSurface = BorderRadius.circular(surface);
  static BorderRadius borderInput = BorderRadius.circular(input);
  static BorderRadius borderIconButton = BorderRadius.circular(iconButton);
}
