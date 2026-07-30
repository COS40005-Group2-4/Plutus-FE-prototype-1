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

    final Finder fade = find.ancestor(
        of: find.text('staggered'), matching: find.byType(FadeTransition)).first;
    double opacity() => tester.widget<FadeTransition>(fade).opacity.value;

    // t=40ms: the 80ms (40ms × index 2) delay timer has not fired.
    await tester.pump(const Duration(milliseconds: 40));
    expect(opacity(), 0.0);

    // t=100ms: the timer fired at 80ms and the ticker's first tick lands
    // here with zero elapsed time — value still 0; progress shows next frame.
    await tester.pump(const Duration(milliseconds: 60));

    // t=200ms: 100ms into the 400ms animation — mid-flight.
    await tester.pump(const Duration(milliseconds: 100));
    expect(opacity(), greaterThan(0.0));
    expect(opacity(), lessThan(1.0));

    await tester.pumpAndSettle();
    expect(opacity(), 1.0);
  });
}
