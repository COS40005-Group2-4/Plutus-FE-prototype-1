import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/report_config.dart';
import '../../models/report_data.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';
import '../../theme/plutus_tokens.dart';
import 'report_section_header.dart';
import 'report_ai_recommendation.dart';

class SpendingBreakdownSection extends StatelessWidget {
  final ReportDataModel data;

  const SpendingBreakdownSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    const PlutusTokens doc = PlutusTokens.dark;
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
          _buildEmpty(l10n, doc)
        else
          _buildTable(categories, l10n, doc),
        if (rec != null)
          ReportAiRecommendation(
            recommendation: rec,
          ),
      ],
    );
  }

  Widget _buildEmpty(AppLocalizations l10n, PlutusTokens doc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
        child: Text(
          l10n.translate('report_no_spending_data'),
          style: TextStyle(color: doc.textMuted, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildTable(
      List<SpendingCategoryData> categories, AppLocalizations l10n, PlutusTokens doc) {
    return Container(
      decoration: BoxDecoration(
        color: doc.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: doc.border),
      ),
      child: Column(
        children: <Widget>[
          _buildHeaderRow(l10n, doc),
          Divider(height: 1, color: doc.border),
          ...categories
              .asMap()
              .entries
              .map((MapEntry<int, SpendingCategoryData> entry) {
            return Column(
              children: <Widget>[
                _buildCategoryRow(entry.value, entry.key, data, doc),
                if (entry.key < categories.length - 1)
                  Divider(height: 1, color: doc.border),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(AppLocalizations l10n, PlutusTokens doc) {
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
              style: TextStyle(
                fontSize: 10,
                color: doc.textMuted,
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
              style: TextStyle(
                fontSize: 10,
                color: doc.textMuted,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '%',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 10,
                color: doc.textMuted,
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
              style: TextStyle(
                fontSize: 10,
                color: doc.textMuted,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(
      SpendingCategoryData cat, int index, ReportDataModel data, PlutusTokens doc) {
    final double changePercent = cat.changePercent;
    final bool isUp = changePercent > 0;
    final Color changeColor = isUp ? doc.error.text : doc.success.text;
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
                    color: doc.chartCategorical[
                        index % doc.chartCategorical.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    cat.category,
                    style: TextStyle(
                      fontSize: 13,
                      color: doc.text,
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
              style: TextStyle(
                fontSize: 13,
                color: doc.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${cat.percentage.toStringAsFixed(1)}%',
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 12, color: doc.textSecondary),
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
