import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/theme/plutus_tokens.dart';

void main() {
  group('PlutusTokens', () {
    test('light and dark expose the full gold/navy token set', () {
      expect(PlutusTokens.light.bg, const Color(0xFFF7F8FA));
      expect(PlutusTokens.light.gold, const Color(0xFFC9970F));
      expect(PlutusTokens.light.text, const Color(0xFF131C3D));
      expect(PlutusTokens.dark.bg, const Color(0xFF0C1120));
      expect(PlutusTokens.dark.gold, const Color(0xFFE0B32F));
      expect(PlutusTokens.light.chartCategorical, hasLength(6));
      expect(PlutusTokens.dark.chartCategorical, hasLength(6));
      expect(PlutusTokens.light.heatmapRamp, hasLength(5));
      expect(PlutusTokens.light.success.dot, const Color(0xFF079455));
      expect(PlutusTokens.light.shadowLow, isNotEmpty);
    });

    test('lerp at t=0 and t=1 returns endpoint values', () {
      final PlutusTokens at0 = PlutusTokens.light.lerp(PlutusTokens.dark, 0.0);
      final PlutusTokens at1 = PlutusTokens.light.lerp(PlutusTokens.dark, 1.0);
      expect(at0.bg, PlutusTokens.light.bg);
      expect(at0.success.text, PlutusTokens.light.success.text);
      expect(at1.bg, PlutusTokens.dark.bg);
      expect(at1.goldWeak, PlutusTokens.dark.goldWeak);
    });

    test('lerp midpoint blends between light and dark', () {
      final PlutusTokens mid = PlutusTokens.light.lerp(PlutusTokens.dark, 0.5);
      expect(mid.bg, Color.lerp(PlutusTokens.light.bg, PlutusTokens.dark.bg, 0.5));
      expect(mid.gold, Color.lerp(PlutusTokens.light.gold, PlutusTokens.dark.gold, 0.5));
    });

    test('copyWith overrides a single field and keeps the rest', () {
      final PlutusTokens t = PlutusTokens.light.copyWith(gold: const Color(0xFF000000));
      expect(t.gold, const Color(0xFF000000));
      expect(t.bg, PlutusTokens.light.bg);
    });
  });
}
