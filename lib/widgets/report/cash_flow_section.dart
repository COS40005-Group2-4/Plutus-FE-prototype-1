import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/report_config.dart';
import '../../models/report_data.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';
import '../../theme/plutus_tokens.dart';
import 'report_section_header.dart';
import 'report_ai_recommendation.dart';

class CashFlowSection extends StatelessWidget {
  final ReportDataModel data;

  const CashFlowSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    const PlutusTokens doc = PlutusTokens.dark;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final SectionRecommendation? rec =
        data.recommendations[ReportSection.cashFlow];

    final double net = data.netSavings;
    final bool positive = net >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ReportSectionHeader(
          title: l10n.translate('report_sec_cashflow'),
          icon: Icons.swap_horiz_rounded,
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: _buildFlowCard(
                label: l10n.translate('report_inflow'),
                value: data.totalIncome,
                data: data,
                color: doc.success.text,
                icon: Icons.arrow_downward_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildFlowCard(
                label: l10n.translate('report_outflow'),
                value: data.totalExpenses,
                data: data,
                color: doc.error.text,
                icon: Icons.arrow_upward_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildFlowCard(
                label: l10n.translate('report_net'),
                value: net,
                data: data,
                color: positive ? doc.success.text : doc.error.text,
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
            color: doc.surfaceSubtle,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: doc.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                positive ? Icons.check_circle_outline : Icons.info_outline,
                color: positive ? doc.success.text : doc.warning.text,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                positive
                    ? l10n.translate('report_positive_cashflow')
                    : l10n.translate('report_negative_cashflow'),
                style: TextStyle(
                  fontSize: 13,
                  color: positive ? doc.textSecondary : doc.warning.text,
                ),
              ),
            ],
          ),
        ),
        if (rec != null)
          ReportAiRecommendation(
            recommendation: rec,
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
              const SizedBox(width: AppSpacing.xs),
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
