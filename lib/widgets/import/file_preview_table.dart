import 'package:flutter/material.dart';
import '../../models/ai/category_suggestion.dart';
import 'ai_category_field.dart';

class FilePreviewTable extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final Map<int, List<CategorySuggestion>> aiSuggestions;
  final Set<int> selectedIndices;
  final ValueChanged<Set<int>> onSelectionChanged;
  final void Function(int index, Map<String, dynamic> updated) onTransactionEdited;
  final void Function(int index, String category) onCategoryChanged;
  final bool isAiLoading;
  final int aiProgress;
  final int aiTotal;

  static const List<String> _expenseCategories = [
    'Food', 'Transportation', 'Entertainment', 'Shopping',
    'Bills', 'Healthcare', 'Education', 'Other',
  ];

  const FilePreviewTable({
    super.key,
    required this.transactions,
    required this.aiSuggestions,
    required this.selectedIndices,
    required this.onSelectionChanged,
    required this.onTransactionEdited,
    required this.onCategoryChanged,
    required this.isAiLoading,
    this.aiProgress = 0,
    this.aiTotal = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allSelected = selectedIndices.length == transactions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Checkbox(
                value: allSelected,
                tristate: true,
                onChanged: (_) {
                  if (allSelected) {
                    onSelectionChanged({});
                  } else {
                    onSelectionChanged(Set.from(List.generate(transactions.length, (i) => i)));
                  }
                },
              ),
              Text(
                '${transactions.length} transactions found, ${selectedIndices.length} selected',
                style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),
        // AI progress
        if (isAiLoading && aiTotal > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Categorizing... $aiProgress/$aiTotal', style: TextStyle(fontSize: 12, color: theme.colorScheme.primary)),
                const SizedBox(height: 4),
                LinearProgressIndicator(value: aiTotal > 0 ? aiProgress / aiTotal : 0),
              ],
            ),
          ),
        const Divider(height: 1),
        // List
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) return _buildCardList(context);
              return _buildDataTable(context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCardList(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final txn = transactions[index];
        final isSelected = selectedIndices.contains(index);
        final suggestions = aiSuggestions[index] ?? [];
        final suggestedCategory = suggestions.isNotEmpty ? suggestions.first.displayName : null;
        final txnCategory = txn['category'] as String? ?? suggestedCategory;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (_) {
                    final newSet = Set<int>.from(selectedIndices);
                    isSelected ? newSet.remove(index) : newSet.add(index);
                    onSelectionChanged(newSet);
                  },
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(txn['payee'] as String? ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                          Text('${txn['amount']} ${txn['currency'] ?? 'VND'}', style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(txn['date'] as String? ?? '', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                      const SizedBox(height: 8),
                      AiCategoryField(
                        categories: _expenseCategories,
                        selectedCategory: txnCategory,
                        isExpense: true,
                        onCategoryChanged: (val) { if (val != null) onCategoryChanged(index, val); },
                        aiSuggestions: suggestions,
                        isAiLoading: isAiLoading,
                        isAiSuggested: suggestions.isNotEmpty,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataTable(BuildContext context) {
    return SingleChildScrollView(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Payee')),
          DataColumn(label: Text('Amount'), numeric: true),
          DataColumn(label: Text('Category')),
        ],
        rows: List.generate(transactions.length, (index) {
          final txn = transactions[index];
          final isSelected = selectedIndices.contains(index);
          final suggestions = aiSuggestions[index] ?? [];
          final suggestedCategory = suggestions.isNotEmpty ? suggestions.first.displayName : null;
          final txnCategory = txn['category'] as String? ?? suggestedCategory;

          return DataRow(
            selected: isSelected,
            cells: [
              DataCell(Checkbox(
                value: isSelected,
                onChanged: (_) {
                  final newSet = Set<int>.from(selectedIndices);
                  isSelected ? newSet.remove(index) : newSet.add(index);
                  onSelectionChanged(newSet);
                },
              )),
              DataCell(Text(txn['date'] as String? ?? '')),
              DataCell(Text(txn['payee'] as String? ?? '')),
              DataCell(Text('${txn['amount']} ${txn['currency'] ?? 'VND'}')),
              DataCell(SizedBox(
                width: 200,
                child: DropdownButton<String>(
                  value: _expenseCategories.contains(txnCategory) ? txnCategory : null,
                  isExpanded: true,
                  underline: const SizedBox(),
                  hint: Text(txnCategory ?? 'Select'),
                  items: _expenseCategories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (val) { if (val != null) onCategoryChanged(index, val); },
                ),
              )),
            ],
          );
        }),
      ),
    );
  }
}
