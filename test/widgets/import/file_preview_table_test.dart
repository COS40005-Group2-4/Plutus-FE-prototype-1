import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/widgets/import/file_preview_table.dart';

void main() {
  final testTransactions = [
    {'date': '2026-03-28', 'payee': 'Starbucks', 'amount': 85000.0, 'currency': 'VND', 'type': 'expense'},
    {'date': '2026-03-27', 'payee': 'Grab', 'amount': 25000.0, 'currency': 'VND', 'type': 'expense'},
  ];

  group('FilePreviewTable', () {
    testWidgets('displays all transactions', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 500,
            child: FilePreviewTable(
              transactions: testTransactions,
              aiSuggestions: const {},
              selectedIndices: {0, 1},
              onSelectionChanged: (_) {},
              onTransactionEdited: (_, _) {},
              onCategoryChanged: (_, _) {},
              isAiLoading: false,
            ),
          ),
        ),
      ));
      expect(find.text('Starbucks'), findsOneWidget);
      expect(find.text('Grab'), findsOneWidget);
    });

    testWidgets('shows transaction count summary', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 500,
            child: FilePreviewTable(
              transactions: testTransactions,
              aiSuggestions: const {},
              selectedIndices: {0, 1},
              onSelectionChanged: (_) {},
              onTransactionEdited: (_, _) {},
              onCategoryChanged: (_, _) {},
              isAiLoading: false,
            ),
          ),
        ),
      ));
      expect(find.textContaining('2 transactions'), findsOneWidget);
    });

    testWidgets('has select-all and per-row checkboxes', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 500,
            child: FilePreviewTable(
              transactions: testTransactions,
              aiSuggestions: const {},
              selectedIndices: {0, 1},
              onSelectionChanged: (_) {},
              onTransactionEdited: (_, _) {},
              onCategoryChanged: (_, _) {},
              isAiLoading: false,
            ),
          ),
        ),
      ));
      final checkboxes = find.byType(Checkbox);
      expect(checkboxes, findsNWidgets(3)); // 1 select-all + 2 rows
    });
  });
}
