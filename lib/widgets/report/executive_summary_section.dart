import 'package:flutter/material.dart';
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
        const ReportSectionHeader(
          title: 'Executive Summary',
          icon: Icons.bar_chart_rounded,
        ),
        const Text(
          'Here\'s a snapshot of your financial health this period. '
          'Each metric is compared against the previous period to help you track progress.',
          style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.6),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildMetricWithDescription(
          card: ReportMetricCard(
            label: 'NET SAVINGS',
            value: data.formatAmount(netSavings, compact: true),
            changeText: netChangePct.isNotEmpty ? netChangePct : null,
            changeColor: netUp ? AppColors.incomeAccent : AppColors.expenseAccent,
            accentColor: AppColors.savingsAccent,
          ),
          description:
              'The difference between your total income and expenses. A positive number means you saved money.',
        ),
        const SizedBox(height: AppSpacing.md),
        _buildMetricWithDescription(
          card: ReportMetricCard(
            label: 'SAVINGS RATE',
            value: '${savingsRate.toStringAsFixed(1)}%',
            changeText: rateChange,
            changeColor: rateUp ? AppColors.incomeAccent : AppColors.expenseAccent,
            accentColor: AppColors.primary,
          ),
          description:
              'The percentage of income you kept as savings. Financial advisors recommend at least 20%.',
        ),
        const SizedBox(height: AppSpacing.md),
        _buildMetricWithDescription(
          card: ReportMetricCard(
            label: 'TRANSACTIONS',
            value: txCount.toString(),
            changeText: txChange,
            changeColor: Colors.white54,
            accentColor: Colors.white70,
          ),
          description: 'Total number of recorded transactions this period.',
        ),
        const SizedBox(height: AppSpacing.md),
        _buildMetricWithDescription(
          card: ReportMetricCard(
            label: 'HEALTH SCORE',
            value: score != null ? '$score/100' : 'N/A',
            changeText: scoreChange.isNotEmpty ? scoreChange : null,
            changeColor: scoreUp ? AppColors.incomeAccent : AppColors.expenseAccent,
            accentColor: AppColors.primary,
          ),
          description:
              'An overall measure of your financial health from 0 to 100, based on savings, consistency, and spending patterns.',
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
