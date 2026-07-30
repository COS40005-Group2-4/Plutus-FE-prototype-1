import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/report_config.dart';
import '../../models/report_data.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';
import '../../theme/plutus_tokens.dart';
import 'report_section_header.dart';
import 'report_ai_recommendation.dart';

class IncomeAnalysisSection extends StatelessWidget {
  final ReportDataModel data;

  const IncomeAnalysisSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    const PlutusTokens doc = PlutusTokens.dark;
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
            color: doc.success.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: doc.success.border,
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
                      style: TextStyle(
                        fontSize: 10,
                        color: doc.textMuted,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      data.formatAmount(data.totalIncome),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: doc.text,
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
                          ? doc.success.text
                          : doc.error.text,
                    ),
                  ),
                  Text(
                    l10n.translate('report_vs_prev_period'),
                    style: TextStyle(fontSize: 11, color: doc.textMuted),
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
                style: TextStyle(color: doc.textMuted, fontSize: 14),
              ),
            ),
          )
        else ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          ...sources.map((IncomeSourceData src) => _buildSourceRow(src, data, doc)),
        ],
        if (rec != null)
          ReportAiRecommendation(
            recommendation: rec,
          ),
      ],
    );
  }

  Widget _buildSourceRow(IncomeSourceData src, ReportDataModel data, PlutusTokens doc) {
    final bool varUp = src.variance >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Text(
              src.source,
              style: TextStyle(fontSize: 13, color: doc.textSecondary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              data.formatAmount(src.amount),
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                color: doc.text,
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
                color: varUp ? doc.success.text : doc.error.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
