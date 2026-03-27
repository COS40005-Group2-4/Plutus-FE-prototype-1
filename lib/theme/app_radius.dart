import 'package:flutter/material.dart';

/// Standardized corner radius scale.
/// Values: 4, 8, 12, 16, 24 (replaces arbitrary 10, 15, 20 values).
class AppRadius {
  AppRadius._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  static BorderRadius borderXs = BorderRadius.circular(xs);
  static BorderRadius borderSm = BorderRadius.circular(sm);
  static BorderRadius borderMd = BorderRadius.circular(md);
  static BorderRadius borderLg = BorderRadius.circular(lg);
  static BorderRadius borderXl = BorderRadius.circular(xl);
}
