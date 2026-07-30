import 'package:flutter/animation.dart';

/// Motion constants for the gold/navy design system (spec §2: fast 150 / medium 250 / slow 400, easeOutCubic emphasis).
/// Standard motion durations.
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  static const Curve standard = Curves.easeInOutCubic;
  static const Curve emphasized = Curves.easeOutCubic;
}
