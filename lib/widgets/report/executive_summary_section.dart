import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/report_config.dart';
import '../../models/report_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'report_section_header.dart';
import 'report_metric_card.dart';
import 'report_ai_recommendation.dart';

class ExecutiveSummarySection extends StatelessWidget {
  final ReportDataModel data;

  const ExecutiveSummarySection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final double netSavings = data.netSavings;
    final double compNetSavings = data.comparisonNetSavings;
    final double savingsRate = data.savingsRate;
    final double compSavingsRate = data.comparisonSavingsRate;
    final int txCount = data.transactionCount;
    final int compTxCount = data.comparisonTransactionCount;
    final int? score = data.healthScore?.score;
    final int? prevScore = data.healthScore?.previousScore;

    final bool netUp = netSavings >= compNetSavings;
    final bool rateUp = savingsRate >= compSavingsRate;
    final bool txUp = txCount >= compTxCount;
    final bool scoreUp = score != null && prevScore != null && score >= prevScore;

    final String netChangePct = compNetSavings != 0
        ? '${netUp ? '+' : ''}${((netSavings - compNetSavings) / compNetSavings * 100).toStringAsFixed(1)}% MoM'
        : '';
    final String rateChange = '${rateUp ? '+' : ''}${(savingsRate - compSavingsRate).toStringAsFixed(1)}pp MoM';
    final String txChange =
        '${txUp ? '+' : ''}${txCount - compTxCount} vs prev period';
    final String scoreChange = (score != null && prevScore != null)
        ? '${scoreUp ? '+' : ''}${score - prevScore} pts MoM'
        : '';

    final SectionRecommendation? rec =
        data.recommendations[ReportSection.executiveSummary];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ReportSectionHeader(
          title: l10n.translate('report_sec_summary'),
          icon: Icons.bar_chart_rounded,
        ),
        Text(
          l10n.translate('report_summary_desc'),
          style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.6),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildMetricWithDescription(
          card: ReportMetricCard(
            label: l10n.translate('report_net_savings'),
            value: data.formatAmount(netSavings, compact: true),
            changeText: netChangePct.isNotEmpty ? netChangePct : null,
            changeColor: netUp ? AppColors.incomeAccent : AppColors.expenseAccent,
            accentColor: AppColors.savingsAccent,
          ),
          description: l10n.translate('report_net_savings_desc'),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildMetricWithDescription(
          card: ReportMetricCard(
            label: l10n.translate('report_savings_rate'),
            value: '${savingsRate.toStringAsFixed(1)}%',
            changeText: rateChange,
            changeColor: rateUp ? AppColors.incomeAccent : AppColors.expenseAccent,
            accentColor: AppColors.primary,
          ),
          description: l10n.translate('report_savings_rate_desc'),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildMetricWithDescription(
          card: ReportMetricCard(
            label: l10n.translate('report_transactions'),
            value: txCount.toString(),
            changeText: txChange,
            changeColor: Colors.white54,
            accentColor: Colors.white70,
          ),
          description: l10n.translate('report_transactions_desc'),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildMetricWithDescription(
          card: ReportMetricCard(
            label: l10n.translate('report_health_score'),
            value: score != null ? '$score/100' : 'N/A',
            changeText: scoreChange.isNotEmpty ? scoreChange : null,
            changeColor: scoreUp ? AppColors.incomeAccent : AppColors.expenseAccent,
            accentColor: AppColors.primary,
          ),
          description: l10n.translate('report_health_score_desc'),
        ),
        if (rec != null)
          ReportAiRecommendation(
            recommendation: rec,
            accentColor: AppColors.primary,
          ),
      ],
    );
  }

  Widget _buildMetricWithDescription({
    required ReportMetricCard card,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        card,
        const SizedBox(height: AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white38,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
