import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/report_config.dart';
import '../../models/report_data.dart';
import '../../models/ai/insight.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';
import 'report_section_header.dart';
import 'report_ai_recommendation.dart';

class ForecastSection extends StatelessWidget {
  final ReportDataModel data;

  const ForecastSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Forecast? forecast = data.forecast;
    final SectionRecommendation? rec =
        data.recommendations[ReportSection.forecast];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ReportSectionHeader(
          title: l10n.translate('report_sec_forecast'),
          icon: Icons.auto_graph_rounded,
        ),
        if (forecast == null)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
              child: Text(
                l10n.translate('report_no_forecast_data'),
                style: const TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ),
          )
        else ...<Widget>[
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Text(
              forecast.summary,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ),
          if (forecast.projectedBalance.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            ...forecast.projectedBalance.entries
                .map((MapEntry<String, double> entry) =>
                    _buildProjectionRow(entry.key, entry.value)),
          ],
        ],
        if (rec != null)
          ReportAiRecommendation(
            recommendation: rec,
            accentColor: AppColors.primary,
          ),
      ],
    );
  }

  Widget _buildProjectionRow(String label, double value) {
    final bool pos = value >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.white54),
          ),
          Text(
            '${pos ? '' : '-'}${value.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: pos ? AppColors.incomeAccent : AppColors.expenseAccent,
            ),
          ),
        ],
      ),
    );
  }
}
