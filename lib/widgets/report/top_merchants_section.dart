import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/report_config.dart';
import '../../models/report_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';
import 'report_section_header.dart';
import 'report_ai_recommendation.dart';

class TopMerchantsSection extends StatelessWidget {
  final ReportDataModel data;

  const TopMerchantsSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<MerchantData>? merchants = data.topMerchants;
    final SectionRecommendation? rec =
        data.recommendations[ReportSection.topMerchants];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ReportSectionHeader(
          title: l10n.translate('report_sec_merchants'),
          icon: Icons.store_outlined,
        ),
        if (merchants == null || merchants.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
              child: Text(
                l10n.translate('report_no_merchant_data'),
                style: const TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ),
          )
        else
          Column(
            children: merchants
                .asMap()
                .entries
                .map((MapEntry<int, MerchantData> entry) =>
                    _buildMerchantRow(entry.value, entry.key, l10n))
                .toList(),
          ),
        if (rec != null)
          ReportAiRecommendation(
            recommendation: rec,
            accentColor: AppColors.primary,
          ),
      ],
    );
  }

  Widget _buildMerchantRow(MerchantData merchant, int index, AppLocalizations l10n) {
    final bool changeUp = merchant.changePercent > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.chartPalette[index % AppColors.chartPalette.length]
                  .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.chartPalette[
                    index % AppColors.chartPalette.length],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  merchant.name,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${merchant.category} • ${merchant.transactionCount} ${l10n.translate('report_col_txns').toLowerCase()}',
                  style: const TextStyle(fontSize: 12, color: Colors.white38),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                merchant.amount.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${changeUp ? '+' : ''}${merchant.changePercent.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 11,
                  color: changeUp
                      ? AppColors.expenseAccent
                      : AppColors.incomeAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
