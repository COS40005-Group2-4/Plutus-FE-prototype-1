import 'package:flutter/material.dart';

/// Soft, modern elevation system. Replaces heavy Material drop-shadows
/// with subtle layered shadows tuned per brightness.
class AppElevation {
  AppElevation._();

  static List<BoxShadow> low(Brightness b) => b == Brightness.dark
      ? const <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ]
      : const <BoxShadow>[
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ];

  static List<BoxShadow> medium(Brightness b) => b == Brightness.dark
      ? const <BoxShadow>[
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 24,
            offset: Offset(0, 6),
          ),
        ]
      : const <BoxShadow>[
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ];

  static List<BoxShadow> high(Brightness b) => b == Brightness.dark
      ? const <BoxShadow>[
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 40,
            offset: Offset(0, 12),
          ),
        ]
      : const <BoxShadow>[
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ];
}

/// Standard motion durations.
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  static const Curve standard = Curves.easeInOutCubic;
  static const Curve emphasized = Curves.easeOutCubic;
}
