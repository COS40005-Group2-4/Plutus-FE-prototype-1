import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/l10n/app_localizations.dart';
import 'package:plutus_fe_prototype/models/ai/category_suggestion.dart';
import 'package:plutus_fe_prototype/theme/app_theme.dart';
import 'package:plutus_fe_prototype/widgets/import/ai_category_field.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: const [AppLocalizations.delegate],
      supportedLocales: const [Locale('en')],
      home: Scaffold(body: child),
    ));
    await tester.pump();
  }

  group('AiCategoryField', () {
    testWidgets('shows dropdown with categories', (tester) async {
      await pump(tester, AiCategoryField(
        categories: const ['Food', 'Transportation', 'Shopping'],
        selectedCategory: null,
        isExpense: true,
        onCategoryChanged: (_) {},
        aiSuggestions: const [],
        isAiLoading: false,
      ));
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('shows gold dot indicator when suggestion is active (spec §7)', (tester) async {
      await pump(tester, AiCategoryField(
        categories: const ['Food', 'Transportation', 'Shopping'],
        selectedCategory: 'Food',
        isExpense: true,
        onCategoryChanged: (_) {},
        aiSuggestions: const [
          CategorySuggestion(account: 'Expenses:Food', confidence: 0.94),
        ],
        isAiLoading: false,
        isAiSuggested: true,
      ));
      // The sparkle icon was replaced by a small gold dot (spec §7); assert
      // the old icon is gone and an 8x8 circular dot is present (not the
      // InputDecorator's default 48x48 suffixIcon minimum).
      expect(find.byIcon(Icons.auto_awesome), findsNothing);
      final dot = find.byWidgetPredicate((widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration! as BoxDecoration).shape == BoxShape.circle);
      expect(dot, findsOneWidget);
      // The Container's own render box includes its right margin (8px), so
      // the measured box is 16x8 for an 8x8 dot with an 8px trailing gap.
      expect(tester.getSize(dot), const Size(16, 8));
    });

    testWidgets('shows runner-up chips when confidence < 90%', (tester) async {
      await pump(tester, AiCategoryField(
        categories: const ['Food', 'Transportation', 'Shopping'],
        selectedCategory: 'Food',
        isExpense: true,
        onCategoryChanged: (_) {},
        aiSuggestions: const [
          CategorySuggestion(account: 'Expenses:Food', confidence: 0.75),
          CategorySuggestion(account: 'Expenses:Shopping', confidence: 0.42),
        ],
        isAiLoading: false,
        isAiSuggested: true,
      ));
      expect(find.text('Shopping 42%'), findsOneWidget);
    });

    testWidgets('hides runner-up chips when confidence > 90%', (tester) async {
      await pump(tester, AiCategoryField(
        categories: const ['Food', 'Transportation', 'Shopping'],
        selectedCategory: 'Food',
        isExpense: true,
        onCategoryChanged: (_) {},
        aiSuggestions: const [
          CategorySuggestion(account: 'Expenses:Food', confidence: 0.95),
          CategorySuggestion(account: 'Expenses:Shopping', confidence: 0.42),
        ],
        isAiLoading: false,
        isAiSuggested: true,
      ));
      expect(find.text('Shopping 42%'), findsNothing);
    });
  });
}
