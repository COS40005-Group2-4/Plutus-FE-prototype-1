import 'package:flutter/material.dart';
import '../../models/report_config.dart';
import '../../models/report_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';
import 'report_section_header.dart';
import 'report_ai_recommendation.dart';

class CashFlowSection extends StatelessWidget {
  final ReportDataModel data;

  const CashFlowSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final SectionRecommendation? rec =
        data.recommendations[ReportSection.cashFlow];

    final double net = data.netSavings;
    final bool positive = net >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const ReportSectionHeader(
          title: 'Cash Flow',
          icon: Icons.swap_horiz_rounded,
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: _buildFlowCard(
                label: 'INFLOW',
                value: data.totalIncome,
                data: data,
                color: AppColors.incomeAccent,
                icon: Icons.arrow_downward_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildFlowCard(
                label: 'OUTFLOW',
                value: data.totalExpenses,
                data: data,
                color: AppColors.expenseAccent,
                icon: Icons.arrow_upward_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildFlowCard(
                label: 'NET',
                value: net,
                data: data,
                color: positive ? AppColors.incomeAccent : AppColors.expenseAccent,
                icon: positive
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                positive ? Icons.check_circle_outline : Icons.info_outline,
                color: positive ? AppColors.incomeAccent : AppColors.warning,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                positive
                    ? 'Positive cash flow — you saved more than you spent.'
                    : 'Negative cash flow — expenses exceeded income.',
                style: TextStyle(
                  fontSize: 13,
                  color: positive ? Colors.white70 : AppColors.warning,
                ),
              ),
            ],
          ),
        ),
        if (rec != null)
          ReportAiRecommendation(
            recommendation: rec,
            accentColor: AppColors.cashflowAccent,
          ),
      ],
    );
  }

  Widget _buildFlowCard({
    required String label,
    required double value,
    required ReportDataModel data,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            data.formatAmount(value),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
