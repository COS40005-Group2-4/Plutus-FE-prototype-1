import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/report_config.dart';
import '../../models/report_data.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';
import '../../theme/plutus_tokens.dart';
import 'report_section_header.dart';
import 'report_ai_recommendation.dart';

class TopMerchantsSection extends StatelessWidget {
  final ReportDataModel data;

  const TopMerchantsSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    const PlutusTokens doc = PlutusTokens.dark;
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
                style: TextStyle(color: doc.textMuted, fontSize: 14),
              ),
            ),
          )
        else
          Column(
            children: merchants
                .asMap()
                .entries
                .map((MapEntry<int, MerchantData> entry) =>
                    _buildMerchantRow(entry.value, entry.key, l10n, doc))
                .toList(),
          ),
        if (rec != null)
          ReportAiRecommendation(
            recommendation: rec,
          ),
      ],
    );
  }

  Widget _buildMerchantRow(
      MerchantData merchant, int index, AppLocalizations l10n, PlutusTokens doc) {
    final bool changeUp = merchant.changePercent > 0;
    final Color rankColor = doc.chartCategorical[index % doc.chartCategorical.length];
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: doc.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: doc.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: rankColor,
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
                  style: TextStyle(
                    fontSize: 14,
                    color: doc.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${merchant.category} • ${merchant.transactionCount} ${l10n.translate('report_col_txns').toLowerCase()}',
                  style: TextStyle(fontSize: 12, color: doc.textMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                merchant.amount.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 14,
                  color: doc.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${changeUp ? '+' : ''}${merchant.changePercent.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 11,
                  color: changeUp
                      ? doc.error.text
                      : doc.success.text,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
