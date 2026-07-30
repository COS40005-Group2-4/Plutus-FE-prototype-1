import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/report_config.dart';
import '../../models/report_data.dart';
import '../../models/ai/insight.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';
import '../../theme/plutus_tokens.dart';
import 'report_section_header.dart';
import 'report_ai_recommendation.dart';

class ForecastSection extends StatelessWidget {
  final ReportDataModel data;

  const ForecastSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    const PlutusTokens doc = PlutusTokens.dark;
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
                style: TextStyle(color: doc.textMuted, fontSize: 14),
              ),
            ),
          )
        else ...<Widget>[
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: doc.surfaceSubtle,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: doc.border),
            ),
            child: Text(
              forecast.summary,
              style: TextStyle(
                fontSize: 14,
                color: doc.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          if (forecast.projectedBalance.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            ...forecast.projectedBalance.entries
                .map((MapEntry<String, double> entry) =>
                    _buildProjectionRow(entry.key, entry.value, doc)),
          ],
        ],
        if (rec != null)
          ReportAiRecommendation(
            recommendation: rec,
          ),
      ],
    );
  }

  Widget _buildProjectionRow(String label, double value, PlutusTokens doc) {
    final bool pos = value >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(fontSize: 13, color: doc.textSecondary),
          ),
          Text(
            '${pos ? '' : '-'}${value.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: pos ? doc.success.text : doc.error.text,
            ),
          ),
        ],
      ),
    );
  }
}
