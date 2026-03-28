import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:plutus_fe_prototype/models/budget_model.dart';
import 'package:plutus_fe_prototype/providers/auth_provider.dart';
import 'package:plutus_fe_prototype/providers/budget_provider.dart';
import 'package:plutus_fe_prototype/theme/app_spacing.dart';
import 'package:plutus_fe_prototype/theme/app_radius.dart';
import 'package:plutus_fe_prototype/services/currency_service.dart';
import 'package:plutus_fe_prototype/widgets/budget_settings_sheet.dart';

class BudgetSummaryWidget extends StatefulWidget {
  const BudgetSummaryWidget({super.key});

  @override
  State<BudgetSummaryWidget> createState() => _BudgetSummaryWidgetState();
}

class _BudgetSummaryWidgetState extends State<BudgetSummaryWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.currentUserId != null) {
        final provider = context.read<BudgetProvider>();
        provider.setCurrentUser(authProvider.currentUserId!);
        provider.loadBudget();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, provider, _) {
        final budget = provider.activeBudget;

        // Loading state with no budget yet
        if (provider.isLoading && budget == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: const Center(child: CircularProgressIndicator()),
            ),
          );
        }

        // Empty state — no active budget
        if (budget == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No budget set up yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const BudgetSettingsSheet(),
                      );
                    },
                    child: const Text('Create Budget'),
                  ),
                ],
              ),
            ),
          );
        }

        // Full widget
        final cc = budget.currencyCode;
        String fmtCurrency(double v) => CurrencyService.formatAmount(v, cc);

        final now = DateTime.now();
        final periodStart = provider.currentPeriodStart;
        final periodEnd = provider.currentPeriodEnd;
        final totalDays =
            periodEnd.difference(periodStart).inDays.toDouble();
        final elapsedDays =
            now.difference(periodStart).inDays.toDouble().clamp(0.0, totalDays);
        final pacePosition =
            totalDays > 0 ? elapsedDays / totalDays : 0.0;

        final progress = provider.overallProgress.clamp(0.0, 1.0);

        Color progressColor;
        if (provider.overallProgress >= 1.0) {
          progressColor = Colors.red.shade400;
        } else if (provider.overallProgress >= 0.7) {
          progressColor = Colors.amber.shade400;
        } else {
          progressColor = Colors.green.shade400;
        }

        final totalBudgeted = provider.totalBudgeted;
        final totalSpent = provider.totalSpent;
        final totalRemaining = provider.totalRemaining;

        final overBudgetCount = provider.overBudgetCount;
        final warningCount = provider.warningCount;

        final periodLabel = _periodLabel(budget.periodType, periodStart);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Period navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => provider.navigatePeriod(-1),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Text(
                      periodLabel,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => provider.navigatePeriod(1),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // 2. Progress bar with pace marker
                LayoutBuilder(
                  builder: (context, constraints) {
                    final barWidth = constraints.maxWidth;
                    return SizedBox(
                      height: 12,
                      child: Stack(
                        children: [
                          // Background
                          Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: AppRadius.borderSm,
                            ),
                          ),
                          // Fill
                          FractionallySizedBox(
                            widthFactor: progress,
                            child: Container(
                              height: 12,
                              decoration: BoxDecoration(
                                color: progressColor,
                                borderRadius: AppRadius.borderSm,
                              ),
                            ),
                          ),
                          // Today pace marker
                          if (pacePosition > 0 && pacePosition < 1)
                            Positioned(
                              left: barWidth * pacePosition - 1,
                              top: -2,
                              child: Container(
                                width: 2,
                                height: 16,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // 3. Summary tiles: Budgeted, Spent, Left
                Row(
                  children: [
                    _SummaryTile(
                      label: 'BUDGETED',
                      value: fmtCurrency(totalBudgeted),
                      valueColor:
                          Theme.of(context).colorScheme.onSurface,
                    ),
                    _SummaryTile(
                      label: 'SPENT',
                      value: fmtCurrency(totalSpent),
                      valueColor: Colors.red.shade400,
                    ),
                    _SummaryTile(
                      label: 'LEFT',
                      value: fmtCurrency(totalRemaining.abs()),
                      valueColor: totalRemaining >= 0
                          ? Colors.green.shade400
                          : Colors.red.shade400,
                    ),
                  ],
                ),

                // 4. Alert banner
                if (overBudgetCount > 0 || warningCount > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _AlertBanner(
                    overBudgetCount: overBudgetCount,
                    warningCount: warningCount,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _periodLabel(BudgetPeriodType periodType, DateTime periodStart) {
    switch (periodType) {
      case BudgetPeriodType.monthly:
        return DateFormat('MMMM yyyy').format(periodStart);
      case BudgetPeriodType.weekly:
      case BudgetPeriodType.biweekly:
        return DateFormat('MMMM yyyy').format(periodStart);
    }
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.bold,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final int overBudgetCount;
  final int warningCount;

  const _AlertBanner({
    required this.overBudgetCount,
    required this.warningCount,
  });

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (overBudgetCount > 0) {
      parts.add('$overBudgetCount over budget');
    }
    if (warningCount > 0) {
      parts.add('$warningCount approaching limit');
    }
    final message = parts.join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.red.shade400.withValues(alpha: 0.12),
        borderRadius: AppRadius.borderSm,
        border: Border.all(color: Colors.red.shade400.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Colors.red.shade400, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red.shade400,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
