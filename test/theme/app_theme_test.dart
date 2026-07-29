import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/theme/app_theme.dart';
import 'package:plutus_fe_prototype/theme/plutus_tokens.dart';

void main() {
  group('AppTheme registers PlutusTokens', () {
    test('light theme carries PlutusTokens.light', () {
      final PlutusTokens? t = AppTheme.light().extension<PlutusTokens>();
      expect(t, isNotNull);
      expect(t!.bg, PlutusTokens.light.bg);
      expect(t.gold, PlutusTokens.light.gold);
    });

    test('dark theme carries PlutusTokens.dark', () {
      final PlutusTokens? t = AppTheme.dark().extension<PlutusTokens>();
      expect(t, isNotNull);
      expect(t!.bg, PlutusTokens.dark.bg);
    });

    test('ThemeData.lerp interpolates the extension (theme animation)', () {
      final ThemeData mid = ThemeData.lerp(AppTheme.light(), AppTheme.dark(), 0.5);
      final PlutusTokens? t = mid.extension<PlutusTokens>();
      expect(t, isNotNull);
      expect(t!.bg,
          Color.lerp(PlutusTokens.light.bg, PlutusTokens.dark.bg, 0.5));
    });

    testWidgets('context.tokens resolves inside the widget tree', (tester) async {
      late PlutusTokens seen;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        home: Builder(builder: (BuildContext context) {
          seen = context.tokens;
          return const SizedBox();
        }),
      ));
      expect(seen.surface, PlutusTokens.light.surface);
    });
  });
}
