import 'package:flutter/material.dart';
import '../../models/report_config.dart';
import '../../models/report_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';
import 'report_section_header.dart';
import 'report_ai_recommendation.dart';

class BudgetActualSection extends StatelessWidget {
  final ReportDataModel data;

  const BudgetActualSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final List<BudgetCategoryData>? categories = data.budgetCategories;
    final SectionRecommendation? rec =
        data.recommendations[ReportSection.budgetActual];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const ReportSectionHeader(
          title: 'Budget vs Actual',
          icon: Icons.account_balance_wallet_outlined,
        ),
        if (categories == null || categories.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
              child: Text(
                'No budget data available',
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ),
          )
        else
          Column(
            children: categories
                .map((BudgetCategoryData cat) => _buildBudgetRow(cat))
                .toList(),
          ),
        if (rec != null)
          ReportAiRecommendation(
            recommendation: rec,
            accentColor: AppColors.budgetAccent,
          ),
      ],
    );
  }

  Widget _buildBudgetRow(BudgetCategoryData cat) {
    final double pct = cat.percentage.clamp(0.0, 100.0);
    final Color barColor =
        cat.isOverBudget ? AppColors.expenseAccent : AppColors.incomeAccent;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                cat.category,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: <Widget>[
                  Text(
                    '${cat.actual.toStringAsFixed(0)} / ${cat.budget.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: cat.isOverBudget
                          ? AppColors.expenseAccent
                          : Colors.white54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (cat.isOverBudget) ...<Widget>[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 14,
                      color: AppColors.expenseAccent,
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${pct.toStringAsFixed(0)}% of budget used',
            style: const TextStyle(fontSize: 11, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
