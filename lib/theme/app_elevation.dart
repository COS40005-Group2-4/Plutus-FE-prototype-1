import 'package:flutter/material.dart';

/// Soft, modern elevation system. Replaces heavy Material drop-shadows
/// with subtle layered shadows tuned per brightness.
///
/// Light mode favors a magenta-tinted glow halo, dark mode a violet glow
/// — the new design system reads as ambient color light around cards
/// rather than hard black drop-shadow.
class AppElevation {
  AppElevation._();

  // ── Tinted brand-glow colors (private to keep widgets token-driven) ──
  /// Magenta @ 12% — light-mode card glow.
  static const Color _glowLight = Color(0x1FEC4899);
  /// Violet @ 18% — dark-mode card glow.
  static const Color _glowDark = Color(0x2EA78BFA);

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

  /// Brand-tinted card halo. Use for elevated cards on light/dark canvas.
  /// Light: magenta @ 12% blur 24 y8. Dark: violet @ 18% blur 28 y10.
  static List<BoxShadow> brandGlow(Brightness b) => b == Brightness.dark
      ? const <BoxShadow>[
          BoxShadow(
            color: _glowDark,
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ]
      : const <BoxShadow>[
          BoxShadow(
            color: _glowLight,
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ];

  /// Brand-saturated halo around a FAB / circular CTA. Receives the
  /// resolved brand color so the shadow tints to magenta or violet.
  static List<BoxShadow> fabGlow(Color brand) => <BoxShadow>[
        BoxShadow(
          color: brand.withValues(alpha: 0.40),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  /// Floating bottom-nav shadow. Slightly stronger glow + lifts higher.
  static List<BoxShadow> floatingNav(Brightness b) => b == Brightness.dark
      ? const <BoxShadow>[
          BoxShadow(
            color: Color(0x33A78BFA),
            blurRadius: 40,
            offset: Offset(0, 16),
          ),
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ]
      : const <BoxShadow>[
          BoxShadow(
            color: Color(0x29EC4899),
            blurRadius: 32,
            offset: Offset(0, 14),
          ),
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
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
