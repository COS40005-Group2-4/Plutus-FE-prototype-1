import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:plutus_fe_prototype/models/budget_model.dart';
import 'package:plutus_fe_prototype/providers/budget_provider.dart';
import 'package:plutus_fe_prototype/theme/app_spacing.dart';
import 'package:plutus_fe_prototype/theme/app_radius.dart';
import 'package:plutus_fe_prototype/services/currency_service.dart';
import 'package:plutus_fe_prototype/widgets/budget_settings_sheet.dart';

class CategoryBudgetWidget extends StatelessWidget {
  const CategoryBudgetWidget({super.key});

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _formatAmount(double amount, String currencyCode) {
    return CurrencyService.formatAmount(amount.abs(), currencyCode);
  }

  String _periodLabel(BudgetProvider provider) {
    final start = provider.currentPeriodStart;
    final budget = provider.activeBudget;
    if (budget == null) return '';

    switch (budget.periodType) {
      case BudgetPeriodType.monthly:
        return DateFormat('MMMM yyyy').format(start);
      case BudgetPeriodType.weekly:
        final end = provider.currentPeriodEnd.subtract(const Duration(days: 1));
        return '${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d').format(end)}';
      case BudgetPeriodType.biweekly:
        final end = provider.currentPeriodEnd.subtract(const Duration(days: 1));
        return '${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d').format(end)}';
    }
  }

  Color _statusColor(BudgetStatus status, BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (status) {
      case BudgetStatus.overBudget:
        return cs.error;
      case BudgetStatus.warning:
        return Colors.amber.shade700;
      case BudgetStatus.onTrack:
        return Colors.green.shade600;
    }
  }

  // ---------------------------------------------------------------------------
  // Dialogs
  // ---------------------------------------------------------------------------

  void _showInlineEdit(
    BuildContext context,
    BudgetProvider provider,
    CategorySpending cs,
  ) {
    final currency = provider.activeBudget?.currencyCode ?? 'USD';
    final controller = TextEditingController(
      text: cs.budgetedAmount.toStringAsFixed(0),
    );

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit budget for ${cs.category.name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            prefixText: '${CurrencyService.getCurrencySymbol(currency)} ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? cs.budgetedAmount;
              provider.quickUpdateAmount(cs.category.id!, amount);
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _createBudgetFromUnbudgeted(
    BuildContext context,
    UnbudgetedEntry entry,
  ) {
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Budget for "${entry.accountName}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current spending: \$${NumberFormat('#,##0', 'en_US').format(entry.spent)}',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Monthly budget amount',
                prefixText: '\$ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Full implementation requires BudgetService wired through
              // settings sheet — close for now.
              Navigator.of(ctx).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _openSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const BudgetSettingsSheet(),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, provider, _) {
        // Loading state
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // No active budget — summary widget handles empty state
        if (provider.activeBudget == null) {
          return const SizedBox.shrink();
        }

        final budget = provider.activeBudget!;
        final currency = budget.currencyCode;

        return Card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    // Period navigation
                    _PeriodNav(
                      label: _periodLabel(provider),
                      onPrev: () => provider.navigatePeriod(-1),
                      onNext: () => provider.navigatePeriod(1),
                    ),

                    const Spacer(),

                    // + Add button
                    TextButton.icon(
                      onPressed: () => _openSettings(context),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                      ),
                    ),

                    // ⚙ Settings button
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, size: 20),
                      onPressed: () => _openSettings(context),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Budget settings',
                    ),
                  ],
                ),
              ),

              // ── Category rows ─────────────────────────────────────────────
              ...provider.categorySpending.map((cs) {
                final statusColor = _statusColor(cs.status, context);
                final progress =
                    cs.budgetedAmount > 0
                        ? (cs.spent / cs.budgetedAmount).clamp(0.0, 1.0)
                        : 0.0;
                final rolloverAmount = cs.period?.rolloverAmount ?? 0;
                final hasRollover = rolloverAmount != 0;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: InkWell(
                    borderRadius: AppRadius.borderSm,
                    onTap: () => _showInlineEdit(context, provider, cs),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top row: icon + name + rollover badge | remaining
                          Row(
                            children: [
                              // Emoji icon
                              if (cs.category.icon != null &&
                                  cs.category.icon!.isNotEmpty) ...[
                                Text(
                                  cs.category.icon!,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                              ],

                              // Category name
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        cs.category.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                    // Rollover badge
                                    if (cs.category.rolloverEnabled) ...[
                                      const SizedBox(width: AppSpacing.xs),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.xs,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondaryContainer,
                                          borderRadius: AppRadius.borderXs,
                                        ),
                                        child: Text(
                                          '↻',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSecondaryContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              const SizedBox(width: AppSpacing.sm),

                              // Remaining amount + label
                              GestureDetector(
                                onTap: () =>
                                    _showInlineEdit(context, provider, cs),
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: _formatAmount(
                                          cs.remaining.abs(),
                                          currency,
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: statusColor,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      TextSpan(
                                        text: cs.remaining < 0
                                            ? ' over'
                                            : ' left',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: statusColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: AppSpacing.xs),

                          // Progress bar
                          ClipRRect(
                            borderRadius: AppRadius.borderXs,
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(statusColor),
                              minHeight: 6,
                            ),
                          ),

                          const SizedBox(height: AppSpacing.xs),

                          // Sub-text row
                          Row(
                            children: [
                              // Left: spent + pace warning
                              Expanded(
                                child: Wrap(
                                  spacing: AppSpacing.sm,
                                  children: [
                                    Text(
                                      '${_formatAmount(cs.spent, currency)} spent',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                    if (cs.projectedSpending >
                                        cs.budgetedAmount)
                                      Text(
                                        '⚡ pace: ${_formatAmount(cs.projectedSpending, currency)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color:
                                                  Colors.amber.shade700,
                                            ),
                                      ),
                                  ],
                                ),
                              ),

                              // Right: budgeted amount (with rollover if present)
                              Text(
                                hasRollover
                                    ? '${_formatAmount(cs.category.budgetedAmount, currency)} + ${_formatAmount(rolloverAmount.abs(), currency)} rolled'
                                    : '${_formatAmount(cs.budgetedAmount, currency)} budgeted',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // ── Unbudgeted section ────────────────────────────────────────
              if (provider.unbudgetedSpending.isNotEmpty) ...[
                const Divider(
                  height: AppSpacing.lg,
                  indent: AppSpacing.md,
                  endIndent: AppSpacing.md,
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Unbudgeted Spending',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _formatAmount(
                          provider.unbudgetedSpending
                              .fold(0.0, (sum, e) => sum + e.spent),
                          budget.currencyCode,
                        ),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                ...provider.unbudgetedSpending.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerLow,
                        borderRadius: AppRadius.borderSm,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: entry.accountName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                  TextSpan(
                                    text:
                                        ' · ${_formatAmount(entry.spent, currency)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                _createBudgetFromUnbudgeted(context, entry),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                            ),
                            child: const Text('+ Budget'),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: AppSpacing.md),
              ] else
                const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Period navigation control
// ---------------------------------------------------------------------------

class _PeriodNav extends StatelessWidget {
  const _PeriodNav({
    required this.label,
    required this.onPrev,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onPrev,
          borderRadius: AppRadius.borderXs,
          child: const Padding(
            padding: EdgeInsets.all(AppSpacing.xs),
            child: Icon(Icons.chevron_left, size: 20),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: AppSpacing.xs),
        InkWell(
          onTap: onNext,
          borderRadius: AppRadius.borderXs,
          child: const Padding(
            padding: EdgeInsets.all(AppSpacing.xs),
            child: Icon(Icons.chevron_right, size: 20),
          ),
        ),
      ],
    );
  }
}
