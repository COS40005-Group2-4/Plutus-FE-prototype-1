import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter/widgets.dart' show Brightness;
import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/theme/app_colors.dart';

/// WCAG 2.x relative luminance (sRGB).
double _relativeLuminance(Color c) {
  double channel(double v) {
    final s = v / 255.0;
    return s <= 0.03928 ? s / 12.92 : math.pow((s + 0.055) / 1.055, 2.4) as double;
  }

  // Using deprecated red/green/blue ints is fine here — we want the
  // composited (alpha pre-blended) sRGB primaries. The on-accent helpers
  // return alpha-modulated colors, so we composite over their card
  // surface before measuring luminance.
  return 0.2126 * channel(c.r * 255) +
      0.7152 * channel(c.g * 255) +
      0.0722 * channel(c.b * 255);
}

double _contrastRatio(Color fg, Color bg) {
  final l1 = _relativeLuminance(fg);
  final l2 = _relativeLuminance(bg);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

/// Composites a foreground (which may be alpha-modulated) over its card
/// surface so the contrast measurement reflects what actually paints.
Color _composite(Color fg, Color bg) {
  final a = fg.a;
  final r = fg.r * a + bg.r * (1 - a);
  final g = fg.g * a + bg.g * (1 - a);
  final b = fg.b * a + bg.b * (1 - a);
  return Color.fromARGB(255, (r * 255).round(), (g * 255).round(),
      (b * 255).round());
}

void main() {
  group('on-accent foreground contrast', () {
    test('every dashboard accent clears WCAG-AA 4.5:1 for primary text', () {
      for (final accent in AppColors.dashboardAccents) {
        for (final b in Brightness.values) {
          final bg = AppColors.cardSurfaceForAccent(accent, b);
          final fg = AppColors.onAccentPrimary(accent, b);
          final composited = _composite(fg, bg);
          final ratio = _contrastRatio(composited, bg);
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason:
                'primary on-accent for $accent in $b is $ratio (< 4.5:1)',
          );
        }
      }
    });

    test('every dashboard accent clears 3:1 for secondary text', () {
      for (final accent in AppColors.dashboardAccents) {
        for (final b in Brightness.values) {
          final bg = AppColors.cardSurfaceForAccent(accent, b);
          final fg = AppColors.onAccentSecondary(accent, b);
          final composited = _composite(fg, bg);
          final ratio = _contrastRatio(composited, bg);
          expect(
            ratio,
            greaterThanOrEqualTo(3.0),
            reason:
                'secondary on-accent for $accent in $b is $ratio (< 3:1)',
          );
        }
      }
    });

    test('iconOnAccent meets the WCAG 3:1 non-text target', () {
      for (final accent in AppColors.dashboardAccents) {
        for (final b in Brightness.values) {
          final bg = AppColors.cardSurfaceForAccent(accent, b);
          final fg = AppColors.iconOnAccent(accent, b);
          final composited = _composite(fg, bg);
          final ratio = _contrastRatio(composited, bg);
          expect(
            ratio,
            greaterThanOrEqualTo(3.0),
            reason: 'icon on-accent for $accent in $b is $ratio (< 3:1)',
          );
        }
      }
    });
  });
}
