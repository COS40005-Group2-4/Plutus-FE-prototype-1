import 'package:flutter/material.dart';
import '../../models/ai/category_suggestion.dart';

class AiCategoryField extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final bool isExpense;
  final ValueChanged<String?> onCategoryChanged;
  final List<CategorySuggestion> aiSuggestions;
  final bool isAiLoading;
  final bool isAiSuggested;

  const AiCategoryField({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.isExpense,
    required this.onCategoryChanged,
    required this.aiSuggestions,
    required this.isAiLoading,
    this.isAiSuggested = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topConfidence = aiSuggestions.isNotEmpty ? aiSuggestions.first.confidence : 0.0;
    final showRunnerUps = isAiSuggested && topConfidence < 0.9 && aiSuggestions.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: categories.contains(selectedCategory) ? selectedCategory : null,
          decoration: InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(
              borderSide: isAiSuggested
                  ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
                  : const BorderSide(),
            ),
            enabledBorder: isAiSuggested
                ? OutlineInputBorder(
                    borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                  )
                : null,
            suffixIcon: isAiLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : isAiSuggested
                    ? Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 18)
                    : null,
          ),
          items: categories.map((category) => DropdownMenuItem(
            value: category,
            child: Text(category),
          )).toList(),
          onChanged: onCategoryChanged,
        ),
        if (showRunnerUps) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: aiSuggestions.skip(1).take(2).map((suggestion) {
              final pct = (suggestion.confidence * 100).round();
              return ActionChip(
                label: Text(
                  '${suggestion.displayName} $pct%',
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                ),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onPressed: () => onCategoryChanged(suggestion.displayName),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
