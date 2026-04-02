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
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.6,
          children: <Widget>[
            ReportMetricCard(
              label: 'NET SAVINGS',
              value: '${data.currency}${_fmt(netSavings)}',
              changeText: netChangePct.isNotEmpty ? netChangePct : null,
              changeColor: netUp ? AppColors.incomeAccent : AppColors.expenseAccent,
              accentColor: AppColors.savingsAccent,
            ),
            ReportMetricCard(
              label: 'SAVINGS RATE',
              value: '${savingsRate.toStringAsFixed(1)}%',
              changeText: rateChange,
              changeColor: rateUp ? AppColors.incomeAccent : AppColors.expenseAccent,
              accentColor: AppColors.primary,
            ),
            ReportMetricCard(
              label: 'TRANSACTIONS',
              value: txCount.toString(),
              changeText: txChange,
              changeColor: Colors.white54,
              accentColor: Colors.white70,
            ),
            ReportMetricCard(
              label: 'HEALTH SCORE',
              value: score != null ? '$score/100' : 'N/A',
              changeText: scoreChange.isNotEmpty ? scoreChange : null,
              changeColor: scoreUp ? AppColors.incomeAccent : AppColors.expenseAccent,
              accentColor: AppColors.primary,
            ),
          ],
        ),
        if (rec != null)
          ReportAiRecommendation(
            recommendation: rec,
            accentColor: AppColors.primary,
          ),
      ],
    );
  }

  String _fmt(double value) {
    final bool negative = value < 0;
    final String abs = value.abs() >= 1000
        ? '${(value.abs() / 1000).toStringAsFixed(1)}k'
        : value.abs().toStringAsFixed(0);
    return negative ? '-$abs' : abs;
  }
}
