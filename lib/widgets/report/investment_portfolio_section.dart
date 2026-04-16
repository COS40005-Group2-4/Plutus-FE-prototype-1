import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/report_config.dart';
import '../../models/report_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';
import 'report_section_header.dart';
import 'report_ai_recommendation.dart';

class InvestmentPortfolioSection extends StatelessWidget {
  final ReportDataModel data;

  const InvestmentPortfolioSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
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
          _buildPortfolioSummary(l10n),
        if (holdings == null || holdings.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
              child: Text(
                l10n.translate('report_no_investment_data'),
                style: const TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ),
          )
        else ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          ...holdings.map((InvestmentHoldingData h) => _buildHoldingRow(h)),
        ],
        if (rec != null)
          ReportAiRecommendation(
            recommendation: rec,
            accentColor: AppColors.marketAccent,
          ),
      ],
    );
  }

  Widget _buildPortfolioSummary(AppLocalizations l10n) {
    final double? totalValue = data.portfolioTotalValue;
    final double? returnPct = data.portfolioReturnPercent;
    final double? totalGain = data.portfolioTotalGain;
    final bool gainPos = (totalGain ?? 0) >= 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.marketAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.marketAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.translate('report_total_value'),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white38,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                totalValue != null ? totalValue.toStringAsFixed(2) : 'N/A',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
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
                    color: gainPos ? AppColors.incomeAccent : AppColors.expenseAccent,
                  ),
                ),
                if (totalGain != null)
                  Text(
                    '${gainPos ? '+' : ''}${totalGain.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: gainPos ? AppColors.incomeAccent : AppColors.expenseAccent,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHoldingRow(InvestmentHoldingData holding) {
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
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Text(
              holding.ticker,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              holding.name,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                holding.value.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${returnPos ? '+' : ''}${holding.returnPercent.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 11,
                  color: returnPos ? AppColors.incomeAccent : AppColors.expenseAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
