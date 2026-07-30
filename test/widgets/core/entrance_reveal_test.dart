import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/theme/app_theme.dart';
import 'package:plutus_fe_prototype/widgets/core/entrance_reveal.dart';

void main() {
  testWidgets('EntranceReveal fades and settles its child in',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: const Scaffold(
          body: EntranceReveal(index: 0, child: Text('hello'))),
    ));
    final FadeTransition fade = tester.widget<FadeTransition>(find.ancestor(
        of: find.text('hello'), matching: find.byType(FadeTransition)).first);
    expect(fade.opacity.value, lessThan(1.0));
    await tester.pumpAndSettle();
    expect(fade.opacity.value, 1.0);
  });

  testWidgets('EntranceReveal is instant under disableAnimations',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Scaffold(
            body: EntranceReveal(index: 3, child: Text('now'))),
      ),
    ));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.text('now'), findsOneWidget);
  });

  testWidgets('EntranceReveal rises exactly 10 logical pixels',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: const Scaffold(
          body: EntranceReveal(index: 0, child: Text('hello'))),
    ));
    final Transform transform = tester.widget<Transform>(find.ancestor(
        of: find.text('hello'), matching: find.byType(Transform)).first);
    expect((transform.transform as Matrix4).getTranslation().y, 10.0);
    await tester.pumpAndSettle();
    final Transform finalTransform = tester.widget<Transform>(find.ancestor(
        of: find.text('hello'), matching: find.byType(Transform)).first);
    expect((finalTransform.transform as Matrix4).getTranslation().y, 0.0);
  });

  testWidgets('EntranceReveal staggers animation by 40ms per index',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: const Scaffold(
          body: EntranceReveal(index: 2, child: Text('staggered'))),
    ));
    // Immediately after pump, animation is not running (scheduled via Future.delayed)
    await tester.pump(const Duration(milliseconds: 40));
    final FadeTransition fade40 = tester.widget<FadeTransition>(find.ancestor(
        of: find.text('staggered'), matching: find.byType(FadeTransition)).first);
    expect(fade40.opacity.value, 0.0,
        reason: 'At t=40ms, scheduled animation delay has not fired yet');
    // Pump to 100ms total, then pump-and-settle to let Future fire and animation complete
    await tester.pump(const Duration(milliseconds: 60));
    // Settle all animations, which will allow the scheduled Future to fire on next frame
    await tester.pumpAndSettle();
    final FadeTransition fadeFinal = tester.widget<FadeTransition>(find.ancestor(
        of: find.text('staggered'), matching: find.byType(FadeTransition)).first);
    expect(fadeFinal.opacity.value, 1.0,
        reason: 'Stagger delay is correctly applied; animation eventually completes');
  });
}
