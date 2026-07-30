import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../models/report_data.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';
import '../../theme/plutus_tokens.dart';
import 'report_metric_card.dart';

class CoverSection extends StatelessWidget {
  final ReportDataModel data;

  const CoverSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    const PlutusTokens doc = PlutusTokens.dark;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DateFormat rangeFmt = DateFormat('MMM d, yyyy');
    final String rangeText =
        '${rangeFmt.format(data.config.dateRange.start)} – '
        '${rangeFmt.format(data.config.dateRange.end)}';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
      decoration: BoxDecoration(
        color: doc.heroSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: doc.heroBorder, width: 1),
      ),
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: doc.gold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      data.config.audienceMode.name == 'professional'
                          ? l10n.translate('report_financial_report')
                          : l10n.translate('report_personal_finance_report'),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: doc.text,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      rangeText,
                      style: TextStyle(
                        fontSize: 15,
                        color: doc.textMuted,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            data.userName,
            style: TextStyle(
              fontSize: 16,
              color: doc.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Divider(color: doc.border),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: <Widget>[
              Expanded(
                child: ReportMetricCard(
                  label: l10n.translate('report_total_income'),
                  value: data.formatAmount(data.totalIncome),
                  accentColor: doc.text,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ReportMetricCard(
                  label: l10n.translate('report_total_expenses'),
                  value: data.formatAmount(data.totalExpenses),
                  accentColor: doc.text,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ReportMetricCard(
                  label: l10n.translate('report_health_score'),
                  value: data.healthScore != null
                      ? '${data.healthScore!.score}/100'
                      : 'N/A',
                  accentColor: doc.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            '${l10n.reportGeneratedPrefix}${DateFormat('MMM d, yyyy • h:mm a').format(data.generatedAt)}',
            style: TextStyle(
              fontSize: 11,
              color: doc.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
