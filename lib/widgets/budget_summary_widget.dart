import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:plutus_fe_prototype/models/budget_model.dart';
import 'package:plutus_fe_prototype/providers/auth_notifier.dart';
import 'package:plutus_fe_prototype/providers/budget_notifier.dart';
import 'package:plutus_fe_prototype/theme/app_spacing.dart';
import 'package:plutus_fe_prototype/theme/app_radius.dart';
import 'package:plutus_fe_prototype/services/currency_service.dart';
import 'package:plutus_fe_prototype/widgets/budget_settings_sheet.dart';
import '../l10n/app_localizations.dart';
import '../theme/plutus_tokens.dart';
import 'core/app_card.dart';

final _monthlyPeriodFormatter = DateFormat('MMMM yyyy');

class BudgetSummaryWidget extends ConsumerStatefulWidget {
  const BudgetSummaryWidget({super.key});

  @override
  ConsumerState<BudgetSummaryWidget> createState() => _BudgetSummaryWidgetState();
}

class _BudgetSummaryWidgetState extends ConsumerState<BudgetSummaryWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUserId = ref.read(authNotifierProvider.notifier).currentUserId;
      if (currentUserId != null) {
        ref.read(budgetNotifierProvider.notifier).setCurrentUser(currentUserId);
        ref.read(budgetNotifierProvider.notifier).refreshSpending();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncBudget = ref.watch(budgetNotifierProvider);
    final l10n = AppLocalizations.of(context);
    final PlutusTokens t = context.tokens;

    return asyncBudget.when(
      loading: () => const AppCard(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (provider) {
        final budget = provider.activeBudget;

        // Empty state — no active budget
        if (budget == null) {
          return AppCard(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.budgetNoBudgetYet,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
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
                    child: Text(l10n.budgetCreate),
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
          progressColor = t.error.dot;
        } else if (provider.overallProgress >= 0.7) {
          progressColor = t.warning.dot;
        } else {
          progressColor = t.success.dot;
        }

        final totalBudgeted = provider.totalBudgeted;
        final totalSpent = provider.totalSpent;
        final totalRemaining = provider.totalRemaining;

        final overBudgetCount = provider.overBudgetCount;
        final warningCount = provider.warningCount;

        final periodLabel = _periodLabel(budget.periodType, periodStart);

        return AppCard(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 0. Widget title
                Row(
                  children: [
                    Text(
                      l10n.widgetBudgetTracking,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: t.text,
                          ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Tooltip(
                      message: l10n.widgetHelpBudget,
                      child: Icon(
                        Icons.help_outline,
                        size: 14,
                        color: t.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // 1. Period navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left, color: t.textSecondary),
                      onPressed: () => ref.read(budgetNotifierProvider.notifier).navigatePeriod(-1),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Text(
                      periodLabel,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(color: t.text),
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_right, color: t.textSecondary),
                      onPressed: () => ref.read(budgetNotifierProvider.notifier).navigatePeriod(1),
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
                          // Background — calm surface track.
                          Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: t.surfaceSubtle,
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
                                color: t.textSecondary,
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
                      label: l10n.budgetBudgeted,
                      value: fmtCurrency(totalBudgeted),
                      valueColor: t.text,
                      labelColor: t.textMuted,
                    ),
                    _SummaryTile(
                      label: l10n.budgetSpent,
                      value: fmtCurrency(totalSpent),
                      valueColor: t.text,
                      labelColor: t.textMuted,
                    ),
                    _SummaryTile(
                      label: l10n.budgetLeft,
                      value: fmtCurrency(totalRemaining.abs()),
                      valueColor: t.text,
                      labelColor: t.textMuted,
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
        );
      },
    );
  }

  String _periodLabel(BudgetPeriodType periodType, DateTime periodStart) {
    switch (periodType) {
      case BudgetPeriodType.monthly:
      case BudgetPeriodType.weekly:
      case BudgetPeriodType.biweekly:
        return _monthlyPeriodFormatter.format(periodStart);
    }
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final Color? labelColor;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.valueColor,
    this.labelColor,
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
                  color: labelColor ??
                      Theme.of(context).colorScheme.onSurfaceVariant,
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
    final PlutusTokens t = context.tokens;
    final parts = <String>[];
    if (overBudgetCount > 0) {
      parts.add('$overBudgetCount ${AppLocalizations.of(context).budgetOver}');
    }
    if (warningCount > 0) {
      parts.add('$warningCount ${AppLocalizations.of(context).budgetApproaching}');
    }
    final message = parts.join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: t.error.surface,
        borderRadius: AppRadius.borderSm,
        border: Border.all(color: t.error.border),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: t.error.dot, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: t.error.text,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
