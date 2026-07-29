import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/theme/app_theme.dart';
import 'package:plutus_fe_prototype/theme/plutus_tokens.dart';
import 'package:plutus_fe_prototype/widgets/core/app_card.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) {
    return tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: Center(child: child)),
    ));
  }

  testWidgets('AppCard renders surface, hairline border and low shadow',
      (WidgetTester tester) async {
    await pump(tester, const AppCard(child: Text('hello')));
    final Container container = tester.widget<Container>(find.descendant(
        of: find.byType(AppCard), matching: find.byType(Container)));
    final BoxDecoration deco = container.decoration! as BoxDecoration;
    expect(deco.color, PlutusTokens.light.surface);
    expect((deco.border! as Border).top.color, PlutusTokens.light.border);
    expect(deco.borderRadius, BorderRadius.circular(16));
    expect(deco.boxShadow, PlutusTokens.light.shadowLow);
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('AppCard with onTap responds to taps',
      (WidgetTester tester) async {
    int taps = 0;
    await pump(tester, AppCard(onTap: () => taps++, child: const Text('go')));
    await tester.tap(find.text('go'));
    expect(taps, 1);
  });
}
