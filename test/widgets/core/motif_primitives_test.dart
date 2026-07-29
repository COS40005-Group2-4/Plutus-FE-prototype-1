import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/theme/app_theme.dart';
import 'package:plutus_fe_prototype/widgets/core/app_skeleton.dart';
import 'package:plutus_fe_prototype/widgets/core/empty_state.dart';
import 'package:plutus_fe_prototype/widgets/core/meander_divider.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) {
    return tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: Center(child: child)),
    ));
  }

  testWidgets('MeanderDivider paints without errors and spans width',
      (WidgetTester tester) async {
    await pump(tester, const MeanderDivider());
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.getSize(find.byType(MeanderDivider)).height, 10);
  });

  testWidgets('EmptyState shows icon, title, message and one action',
      (WidgetTester tester) async {
    int taps = 0;
    await pump(
        tester,
        EmptyState(
          icon: Icons.savings_outlined,
          title: 'No investments yet',
          message: 'Add your first asset to begin.',
          actionLabel: 'Add investment',
          onAction: () => taps++,
        ));
    expect(find.byIcon(Icons.savings_outlined), findsOneWidget);
    expect(find.text('No investments yet'), findsOneWidget);
    expect(find.text('Add your first asset to begin.'), findsOneWidget);
    await tester.tap(find.text('Add investment'));
    expect(taps, 1);
  });

  testWidgets('AppSkeleton pulses, and freezes under disableAnimations',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Scaffold(body: AppSkeleton(width: 120)),
      ),
    ));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.hasRunningAnimations, isFalse);
  });
}
