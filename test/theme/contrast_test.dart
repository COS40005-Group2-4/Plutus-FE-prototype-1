import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/theme/plutus_tokens.dart';

double _channel(double c) =>
    c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) =>
    0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b);

double _ratio(Color fg, Color bg) {
  final double l1 = _luminance(fg);
  final double l2 = _luminance(bg);
  final double lighter = math.max(l1, l2);
  final double darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

/// Composites a possibly-translucent [fg] over an opaque [bg] so alpha
/// tokens (e.g. dark goldWeak) are measured as actually rendered.
Color _flatten(Color fg, Color bg) => Color.alphaBlend(fg, bg);

void _check(String name, Color fg, Color bg, double min) {
  final double r = _ratio(fg, bg);
  expect(r, greaterThanOrEqualTo(min),
      reason: '$name: ${r.toStringAsFixed(2)}:1 < $min:1');
}

void main() {
  for (final (String theme, PlutusTokens t) in <(String, PlutusTokens)>[
    ('light', PlutusTokens.light),
    ('dark', PlutusTokens.dark),
  ]) {
    group('WCAG AA — $theme', () {
      test('body text on all neutral surfaces >= 4.5', () {
        for (final (String s, Color bg) in <(String, Color)>[
          ('bg', t.bg),
          ('surface', t.surface),
          ('surfaceSubtle', t.surfaceSubtle),
        ]) {
          _check('$theme text/$s', t.text, bg, 4.5);
          _check('$theme textSecondary/$s', t.textSecondary, bg, 4.5);
          _check('$theme textMuted/$s (caption-only, large-text AA)',
              t.textMuted, bg, 3.0);
        }
      });

      test('gold pairings >= 4.5', () {
        _check('$theme goldText/bg', t.goldText, t.bg, 4.5);
        _check('$theme goldText/surface', t.goldText, t.surface, 4.5);
        _check('$theme goldText/goldWeak', t.goldText,
            _flatten(t.goldWeak, t.surface), 4.5);
        _check('$theme onGold/gold', t.onGold, t.gold, 4.5);
        _check('$theme onGold/goldHover', t.onGold, t.goldHover, 4.5);
      });

      test('brand navy readable on canvas >= 4.5', () {
        _check('$theme brandNavy/bg', t.brandNavy, t.bg, 4.5);
        _check('$theme brandNavy/surface', t.brandNavy, t.surface, 4.5);
      });

      test('status text on status surface >= 4.5', () {
        for (final (String name, StatusColors s) in <(String, StatusColors)>[
          ('success', t.success),
          ('warning', t.warning),
          ('info', t.info),
          ('error', t.error),
        ]) {
          _check('$theme $name.text/$name.surface', s.text,
              _flatten(s.surface, t.surface), 4.5);
        }
      });

      test('hero card figure >= 4.5', () {
        _check('$theme heroText/heroSurface', t.heroText, t.heroSurface, 4.5);
        _check('$theme heroLabel/heroSurface', t.heroLabel, t.heroSurface, 4.5);
      });
    });
  }
}
