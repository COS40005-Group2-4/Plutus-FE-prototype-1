import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/models/ai/category_suggestion.dart';
import 'package:plutus_fe_prototype/widgets/import/ai_category_field.dart';

void main() {
  group('AiCategoryField', () {
    testWidgets('shows dropdown with categories', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AiCategoryField(
            categories: const ['Food', 'Transportation', 'Shopping'],
            selectedCategory: null,
            isExpense: true,
            onCategoryChanged: (_) {},
            aiSuggestions: const [],
            isAiLoading: false,
          ),
        ),
      ));
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('shows AI indicator when suggestion is active', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AiCategoryField(
            categories: const ['Food', 'Transportation', 'Shopping'],
            selectedCategory: 'Food',
            isExpense: true,
            onCategoryChanged: (_) {},
            aiSuggestions: const [
              CategorySuggestion(account: 'Expenses:Food', confidence: 0.94),
            ],
            isAiLoading: false,
            isAiSuggested: true,
          ),
        ),
      ));
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('shows runner-up chips when confidence < 90%', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AiCategoryField(
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
          ),
        ),
      ));
      expect(find.text('Shopping 42%'), findsOneWidget);
    });

    testWidgets('hides runner-up chips when confidence > 90%', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AiCategoryField(
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
          ),
        ),
      ));
      expect(find.text('Shopping 42%'), findsNothing);
    });
  });
}
