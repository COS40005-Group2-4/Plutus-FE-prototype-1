import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/report_config.dart';
import '../../models/report_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';
import 'report_section_header.dart';
import 'report_ai_recommendation.dart';

class IncomeAnalysisSection extends StatelessWidget {
  final ReportDataModel data;

  const IncomeAnalysisSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<IncomeSourceData>? sources = data.incomeSources;
    final SectionRecommendation? rec =
        data.recommendations[ReportSection.incomeAnalysis];

    final bool incomeUp = data.totalIncome >= data.comparisonIncome;
    final double incomeChange = data.comparisonIncome > 0
        ? ((data.totalIncome - data.comparisonIncome) /
                data.comparisonIncome *
                100)
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ReportSectionHeader(
          title: l10n.translate('report_sec_income'),
          icon: Icons.trending_up_rounded,
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.incomeAccent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: AppColors.incomeAccent.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.translate('report_total_income'),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white38,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      data.formatAmount(data.totalIncome),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    '${incomeUp ? '+' : ''}${incomeChange.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: incomeUp
                          ? AppColors.incomeAccent
                          : AppColors.expenseAccent,
                    ),
                  ),
                  Text(
                    l10n.translate('report_vs_prev_period'),
                    style: const TextStyle(fontSize: 11, color: Colors.white38),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (sources == null || sources.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Text(
                l10n.translate('report_no_income_data'),
                style: const TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ),
          )
        else ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          ...sources.map((IncomeSourceData src) => _buildSourceRow(src, data)),
        ],
        if (rec != null)
          ReportAiRecommendation(
            recommendation: rec,
            accentColor: AppColors.incomeAccent,
          ),
      ],
    );
  }

  Widget _buildSourceRow(IncomeSourceData src, ReportDataModel data) {
    final bool varUp = src.variance >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Text(
              src.source,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              data.formatAmount(src.amount),
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${varUp ? '+' : ''}${src.variance.toStringAsFixed(1)}%',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                color: varUp ? AppColors.incomeAccent : AppColors.expenseAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
