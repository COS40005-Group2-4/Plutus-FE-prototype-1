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

  testWidgets('StatusBadge renders every quartet arm from tokens',
      (WidgetTester tester) async {
    const Map<StatusKind, String> labels = <StatusKind, String>{
      StatusKind.success: 'ok',
      StatusKind.warning: 'careful',
      StatusKind.info: 'fyi',
      StatusKind.error: 'bad',
    };
    for (final MapEntry<StatusKind, String> e in labels.entries) {
      await pump(tester, StatusBadge(kind: e.key, label: e.value));
      final StatusColors s = switch (e.key) {
        StatusKind.success => PlutusTokens.light.success,
        StatusKind.warning => PlutusTokens.light.warning,
        StatusKind.info => PlutusTokens.light.info,
        StatusKind.error => PlutusTokens.light.error,
      };
      final Text label = tester.widget<Text>(find.text(e.value));
      expect(label.style!.color, s.text, reason: '${e.key} text');
      final Container pill = tester.widget<Container>(find
          .descendant(
              of: find.byType(StatusBadge), matching: find.byType(Container))
          .first);
      expect((pill.decoration! as BoxDecoration).color, s.surface,
          reason: '${e.key} surface');
    }
  });

  testWidgets('MetricDelta renders exact zero as neutral, no arrow',
      (WidgetTester tester) async {
    await pump(tester, const MetricDelta(percent: 0));
    final Text txt = tester.widget<Text>(find.text('0.0%'));
    expect(txt.style!.color, PlutusTokens.light.textSecondary);
    expect(find.textContaining('▲'), findsNothing);
    expect(find.textContaining('▼'), findsNothing);
  });
}
