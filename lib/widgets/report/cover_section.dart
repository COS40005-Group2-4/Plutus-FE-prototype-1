import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../models/report_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';
import 'report_metric_card.dart';

class CoverSection extends StatelessWidget {
  final ReportDataModel data;

  const CoverSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DateFormat rangeFmt = DateFormat('MMM d, yyyy');
    final String rangeText =
        '${rangeFmt.format(data.config.dateRange.start)} – '
        '${rangeFmt.format(data.config.dateRange.end)}';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF0A1828),
            Color(0xFF1A3A4A),
            Color(0xFF132D3F),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.borderDark, width: 1),
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
                  color: AppColors.primary,
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
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rangeText,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white54,
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
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Divider(color: Colors.white12),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: <Widget>[
              Expanded(
                child: ReportMetricCard(
                  label: l10n.translate('report_total_income'),
                  value: data.formatAmount(data.totalIncome),
                  accentColor: AppColors.incomeAccent,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ReportMetricCard(
                  label: l10n.translate('report_total_expenses'),
                  value: data.formatAmount(data.totalExpenses),
                  accentColor: AppColors.expenseAccent,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ReportMetricCard(
                  label: l10n.translate('report_health_score'),
                  value: data.healthScore != null
                      ? '${data.healthScore!.score}/100'
                      : 'N/A',
                  accentColor: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Generated ${DateFormat('MMM d, yyyy • h:mm a').format(data.generatedAt)}',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

}
