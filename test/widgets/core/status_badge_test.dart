import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/theme/app_theme.dart';
import 'package:plutus_fe_prototype/theme/plutus_tokens.dart';
import 'package:plutus_fe_prototype/widgets/core/metric_delta.dart';
import 'package:plutus_fe_prototype/widgets/core/status_badge.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) {
    return tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: Center(child: child)),
    ));
  }

  testWidgets('StatusBadge pulls the full success quartet',
      (WidgetTester tester) async {
    await pump(tester,
        const StatusBadge(kind: StatusKind.success, label: 'Synced'));
    final Text label = tester.widget<Text>(find.text('Synced'));
    expect(label.style!.color, PlutusTokens.light.success.text);
    final Container pill = tester.widget<Container>(find
        .descendant(
            of: find.byType(StatusBadge), matching: find.byType(Container))
        .first);
    final BoxDecoration deco = pill.decoration! as BoxDecoration;
    expect(deco.color, PlutusTokens.light.success.surface);
    expect((deco.border! as Border).top.color,
        PlutusTokens.light.success.border);
  });

  testWidgets('MetricDelta shows rise in success and fall in error',
      (WidgetTester tester) async {
    await pump(tester, const MetricDelta(percent: 3.2));
    Text txt = tester.widget<Text>(find.text('▲ 3.2%'));
    expect(txt.style!.color, PlutusTokens.light.success.text);

    await pump(tester, const MetricDelta(percent: -1.85, decimals: 2));
    txt = tester.widget<Text>(find.text('▼ 1.85%'));
    expect(txt.style!.color, PlutusTokens.light.error.text);
  });
}
