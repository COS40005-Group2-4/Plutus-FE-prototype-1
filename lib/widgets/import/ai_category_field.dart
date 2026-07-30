import 'package:flutter/material.dart';
import '../../models/ai/category_suggestion.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_spacing.dart';
import '../../theme/plutus_tokens.dart';

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
    final PlutusTokens t = context.tokens;
    final topConfidence = aiSuggestions.isNotEmpty ? aiSuggestions.first.confidence : 0.0;
    final showRunnerUps = isAiSuggested && topConfidence < 0.9 && aiSuggestions.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: categories.contains(selectedCategory) ? selectedCategory : null,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).category,
            filled: isAiSuggested ? true : null,
            fillColor: isAiSuggested ? t.goldSelectedFill : null,
            border: OutlineInputBorder(
              borderSide: isAiSuggested
                  ? BorderSide(color: t.gold, width: 1.5)
                  : const BorderSide(),
            ),
            enabledBorder: isAiSuggested
                ? OutlineInputBorder(
                    borderSide: BorderSide(color: t.gold, width: 1.5),
                  )
                : null,
            suffixIcon: isAiLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : isAiSuggested
                    ? Align(
                        // DropdownButtonFormField forces its own minimum on
                        // suffixIconConstraints to fit the dropdown arrow;
                        // Align/shrink-wrap keeps the dot itself at 8x8
                        // rather than being stretched to fill that box.
                        alignment: Alignment.centerRight,
                        widthFactor: 1.0,
                        heightFactor: 1.0,
                        child: Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: AppSpacing.componentSm),
                          decoration: BoxDecoration(color: t.gold, shape: BoxShape.circle),
                        ),
                      )
                    : null,
          ),
          items: categories.map((category) => DropdownMenuItem(
            value: category,
            child: Text(category),
          )).toList(),
          onChanged: onCategoryChanged,
        ),
        if (showRunnerUps) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 6,
            children: aiSuggestions.skip(1).take(2).map((suggestion) {
              final pct = (suggestion.confidence * 100).round();
              return ActionChip(
                label: Text(
                  '${suggestion.displayName} $pct%',
                  style: TextStyle(fontSize: 12, color: t.textSecondary),
                ),
                backgroundColor: t.surfaceSubtle,
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
