import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:plutus_fe_prototype/models/budget_model.dart';
import 'package:plutus_fe_prototype/providers/budget_provider.dart';
import 'package:plutus_fe_prototype/theme/app_spacing.dart';
import 'package:plutus_fe_prototype/theme/app_radius.dart';
import 'package:plutus_fe_prototype/theme/app_colors.dart';
import 'package:plutus_fe_prototype/services/currency_service.dart';
import 'package:plutus_fe_prototype/widgets/budget_settings_sheet.dart';
import 'package:plutus_fe_prototype/l10n/app_localizations.dart';
import 'package:plutus_fe_prototype/widgets/glass_container.dart';

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
        return AppColors.warning;
      case BudgetStatus.onTrack:
        return AppColors.success;
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
    final l10n = AppLocalizations.of(context);
    final currency = provider.activeBudget?.currencyCode ?? 'USD';
    final controller = TextEditingController(
      text: cs.budgetedAmount.toStringAsFixed(0),
    );

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${l10n.budgetEditFor} ${cs.category.name}'),
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
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? cs.budgetedAmount;
              provider.quickUpdateAmount(cs.category.id!, amount);
              Navigator.of(ctx).pop();
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _createBudgetFromUnbudgeted(
    BuildContext context,
    UnbudgetedEntry entry,
  ) {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${l10n.budgetFor} "${entry.accountName}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.budgetCurrentSpending}: \$${NumberFormat('#,##0', 'en_US').format(entry.spent)}',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: l10n.budgetMonthlyAmount,
                prefixText: '\$ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              // Full implementation requires BudgetService wired through
              // settings sheet — close for now.
              Navigator.of(ctx).pop();
            },
            child: Text(l10n.budgetAdd),
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
    final l10n = AppLocalizations.of(context);
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

        return GlassContainer(
          color: AppColors.categoryBudgetAccent,
          opacity: 0.2,
          borderRadius: AppRadius.lg,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Widget title ──────────────────────────────────────────────
              Text(
                  l10n.categoryBudgetTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              const SizedBox(height: AppSpacing.sm),

              // ── Header ────────────────────────────────────────────────────
              Row(
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
                      label: Text(l10n.budgetAdd),
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
                      tooltip: l10n.budgetSettingsTitle,
                    ),
                  ],
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
                                            ? ' ${l10n.budgetOverLabel}'
                                            : ' ${l10n.budgetLeftLabel}',
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
                                      '${_formatAmount(cs.spent, currency)} ${l10n.budgetSpentLabel}',
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
                                        '⚡ ${l10n.budgetPace}: ${_formatAmount(cs.projectedSpending, currency)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color:
                                                  AppColors.warning,
                                            ),
                                      ),
                                  ],
                                ),
                              ),

                              // Right: budgeted amount (with rollover if present)
                              Text(
                                hasRollover
                                    ? '${_formatAmount(cs.category.budgetedAmount, currency)} + ${_formatAmount(rolloverAmount.abs(), currency)} ${l10n.budgetRolled}'
                                    : '${_formatAmount(cs.budgetedAmount, currency)} ${l10n.budgetBudgetedLabel}',
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
                ),

                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.budgetUnbudgeted,
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

                const SizedBox(height: AppSpacing.sm),

                ...provider.unbudgetedSpending.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
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
                            child: Text(l10n.budgetAddQuick),
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
