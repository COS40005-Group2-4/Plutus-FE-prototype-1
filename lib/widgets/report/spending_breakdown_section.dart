import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/report_config.dart';
import '../../models/report_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';
import 'report_section_header.dart';
import 'report_ai_recommendation.dart';

class SpendingBreakdownSection extends StatelessWidget {
  final ReportDataModel data;

  const SpendingBreakdownSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<SpendingCategoryData>? categories = data.spendingCategories;
    final SectionRecommendation? rec =
        data.recommendations[ReportSection.spendingBreakdown];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ReportSectionHeader(
          title: l10n.translate('report_sec_spending'),
          icon: Icons.pie_chart_outline_rounded,
        ),
        if (categories == null || categories.isEmpty)
          _buildEmpty(l10n)
        else
          _buildTable(categories, l10n),
        if (rec != null)
          ReportAiRecommendation(
            recommendation: rec,
            accentColor: AppColors.expenseAccent,
          ),
      ],
    );
  }

  Widget _buildEmpty(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
        child: Text(
          l10n.translate('report_no_spending_data'),
          style: const TextStyle(color: Colors.white38, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildTable(List<SpendingCategoryData> categories, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: <Widget>[
          _buildHeaderRow(l10n),
          const Divider(height: 1, color: Colors.white12),
          ...categories
              .asMap()
              .entries
              .map((MapEntry<int, SpendingCategoryData> entry) {
            return Column(
              children: <Widget>[
                _buildCategoryRow(entry.value, entry.key, data),
                if (entry.key < categories.length - 1)
                  Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Text(
              l10n.translate('report_col_category'),
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white38,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              l10n.translate('report_col_amount'),
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white38,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Expanded(
            flex: 1,
            child: Text(
              '%',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white38,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              l10n.translate('report_col_mom'),
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white38,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(SpendingCategoryData cat, int index, ReportDataModel data) {
    final double changePercent = cat.changePercent;
    final bool isUp = changePercent > 0;
    final Color changeColor =
        isUp ? AppColors.expenseAccent : AppColors.incomeAccent;
    final String changeStr =
        '${isUp ? '+' : ''}${changePercent.toStringAsFixed(1)}%';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Row(
              children: <Widget>[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.chartPalette[
                        index % AppColors.chartPalette.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    cat.category,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              data.formatAmount(cat.amount),
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${cat.percentage.toStringAsFixed(1)}%',
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              changeStr,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                color: changeColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
