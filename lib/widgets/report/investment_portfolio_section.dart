import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/report_config.dart';
import '../../models/report_data.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';
import '../../theme/plutus_tokens.dart';
import 'report_section_header.dart';
import 'report_ai_recommendation.dart';

class InvestmentPortfolioSection extends StatelessWidget {
  final ReportDataModel data;

  const InvestmentPortfolioSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    const PlutusTokens doc = PlutusTokens.dark;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<InvestmentHoldingData>? holdings = data.holdings;
    final SectionRecommendation? rec =
        data.recommendations[ReportSection.investmentPortfolio];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ReportSectionHeader(
          title: l10n.translate('report_sec_investments'),
          icon: Icons.candlestick_chart_outlined,
        ),
        if (data.portfolioTotalValue != null)
          _buildPortfolioSummary(l10n, doc),
        if (holdings == null || holdings.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
              child: Text(
                l10n.translate('report_no_investment_data'),
                style: TextStyle(color: doc.textMuted, fontSize: 14),
              ),
            ),
          )
        else ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          ...holdings.map((InvestmentHoldingData h) => _buildHoldingRow(h, doc)),
        ],
        if (rec != null)
          ReportAiRecommendation(
            recommendation: rec,
          ),
      ],
    );
  }

  Widget _buildPortfolioSummary(AppLocalizations l10n, PlutusTokens doc) {
    final double? totalValue = data.portfolioTotalValue;
    final double? returnPct = data.portfolioReturnPercent;
    final double? totalGain = data.portfolioTotalGain;
    final bool gainPos = (totalGain ?? 0) >= 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: doc.info.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: doc.info.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.translate('report_total_value'),
                style: TextStyle(
                  fontSize: 10,
                  color: doc.textMuted,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                totalValue != null ? totalValue.toStringAsFixed(2) : 'N/A',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: doc.text,
                ),
              ),
            ],
          ),
          if (returnPct != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  '${gainPos ? '+' : ''}${returnPct.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: gainPos ? doc.success.text : doc.error.text,
                  ),
                ),
                if (totalGain != null)
                  Text(
                    '${gainPos ? '+' : ''}${totalGain.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: gainPos ? doc.success.text : doc.error.text,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHoldingRow(InvestmentHoldingData holding, PlutusTokens doc) {
    final bool returnPos = holding.returnPercent >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: doc.goldWeak,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Text(
              holding.ticker,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: doc.goldText,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              holding.name,
              style: TextStyle(fontSize: 13, color: doc.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                holding.value.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 13,
                  color: doc.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${returnPos ? '+' : ''}${holding.returnPercent.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 11,
                  color: returnPos ? doc.success.text : doc.error.text,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
