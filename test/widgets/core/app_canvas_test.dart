import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/theme/app_theme.dart';
import 'package:plutus_fe_prototype/theme/plutus_tokens.dart';
import 'package:plutus_fe_prototype/widgets/core/app_canvas.dart';

void main() {
  testWidgets('AppCanvas paints bg, a pointer-transparent wash, and SafeArea child',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: const AppCanvas(child: Text('content')),
    ));

    final ColoredBox base = tester.widget<ColoredBox>(find
        .descendant(of: find.byType(AppCanvas), matching: find.byType(ColoredBox))
        .first);
    expect(base.color, PlutusTokens.light.bg);
    expect(
        find.descendant(
            of: find.byType(AppCanvas), matching: find.byType(IgnorePointer)),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byType(AppCanvas), matching: find.byType(SafeArea)),
        findsOneWidget);
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('AppCanvas wash follows theme brightness',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      home: const AppCanvas(child: SizedBox()),
    ));
    final Container wash = tester.widget<Container>(find
        .descendant(
            of: find.byType(IgnorePointer), matching: find.byType(Container))
        .first);
    final RadialGradient g =
        (wash.decoration! as BoxDecoration).gradient! as RadialGradient;
    expect(g.colors.first.a, closeTo(0.04, 0.005));
  });
}
