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

    test('primary buttons are gold with navy ink, 44px, radius 12', () {
      final ThemeData theme = AppTheme.light();
      final ButtonStyle style = theme.filledButtonTheme.style!;
      expect(style.backgroundColor!.resolve(<WidgetState>{}),
          PlutusTokens.light.gold);
      expect(style.backgroundColor!.resolve(<WidgetState>{WidgetState.hovered}),
          PlutusTokens.light.goldHover);
      expect(style.foregroundColor!.resolve(<WidgetState>{}),
          PlutusTokens.light.onGold);
      expect(style.minimumSize!.resolve(<WidgetState>{}),
          const Size(64, 44));
      final OutlinedBorder shape = style.shape!.resolve(<WidgetState>{})!;
      expect(shape, isA<RoundedRectangleBorder>());
      expect((shape as RoundedRectangleBorder).borderRadius,
          BorderRadius.circular(12));
    });

    test('inputs use hairline borderStrong at rest and 2px gold on focus', () {
      final InputDecorationThemeData d = AppTheme.light().inputDecorationTheme;
      final OutlineInputBorder enabled = d.enabledBorder! as OutlineInputBorder;
      expect(enabled.borderSide.color, PlutusTokens.light.borderStrong);
      expect(enabled.borderSide.width, 1);
      final OutlineInputBorder focused = d.focusedBorder! as OutlineInputBorder;
      expect(focused.borderSide.color, PlutusTokens.light.gold);
      expect(focused.borderSide.width, 2);
    });
  });
}
