import 'package:flutter/material.dart';

/// Soft, modern elevation system. Replaces heavy Material drop-shadows
/// with subtle layered shadows tuned per brightness.
///
/// Shadows are now neutral navy/black — the tinted brand glows have been
/// removed in favor of ambient neutral shadow around cards.
@Deprecated('Transitional shim — use context.tokens (PlutusTokens). Removed in PR4.')
class AppElevation {
  AppElevation._();

  // ── Neutral halo colors (private to keep widgets token-driven) ──
  /// Neutral navy-tinted halo — legacy alias for the low shadow set.
  static const Color _glowLight = Color(0x14131C3D);
  static const Color _glowDark = Color(0x33000000);

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

  /// Neutral card halo. Use for elevated cards on light/dark canvas.
  /// Light: neutral navy @ 8% blur 12 y4. Dark: neutral black @ 20% blur 16 y4.
  static List<BoxShadow> brandGlow(Brightness b) => b == Brightness.dark
      ? const <BoxShadow>[
          BoxShadow(
            color: _glowDark,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ]
      : const <BoxShadow>[
          BoxShadow(
            color: _glowLight,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ];

  /// Neutral halo around a FAB / circular CTA. Ignores the passed brand
  /// color — the shadow no longer tints to the resolved brand hue.
  static List<BoxShadow> fabGlow(Color brand) => const <BoxShadow>[
        BoxShadow(
          color: Color(0x24131C3D),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ];

  /// Floating bottom-nav shadow. Neutral single shadow, lifts higher.
  static List<BoxShadow> floatingNav(Brightness b) => b == Brightness.dark
      ? const <BoxShadow>[
          BoxShadow(
            color: Color(0x59000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ]
      : const <BoxShadow>[
          BoxShadow(
            color: Color(0x1F131C3D),
            blurRadius: 24,
            offset: Offset(0, 8),
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
