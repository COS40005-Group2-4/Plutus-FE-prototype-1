import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/theme/app_theme.dart';
import 'package:plutus_fe_prototype/theme/plutus_tokens.dart';
import 'package:plutus_fe_prototype/widgets/core/hero_card.dart';

void main() {
  testWidgets('HeroCard renders navy surface, gold hairline and serif figure',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: const Scaffold(
        body: HeroCard(label: 'Net worth', value: r'$12,345.67'),
      ),
    ));

    expect(find.text('NET WORTH'), findsOneWidget);
    final Text value = tester.widget<Text>(find.text(r'$12,345.67'));
    expect(value.style!.fontFamily, 'CormorantGaramond');
    expect(value.style!.color, PlutusTokens.light.heroText);

    final Container container = tester.widget<Container>(find
        .descendant(of: find.byType(HeroCard), matching: find.byType(Container))
        .first);
    final BoxDecoration deco = container.decoration! as BoxDecoration;
    expect(deco.color, PlutusTokens.light.heroSurface);
    expect((deco.border! as Border).top.color, PlutusTokens.light.heroBorder);
  });
}
