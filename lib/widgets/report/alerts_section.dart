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

class AlertsSection extends StatelessWidget {
  final ReportDataModel data;

  const AlertsSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    const PlutusTokens doc = PlutusTokens.dark;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<Alert>? alerts = data.alerts;
    final SectionRecommendation? rec =
        data.recommendations[ReportSection.alerts];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ReportSectionHeader(
          title: l10n.translate('report_sec_alerts'),
          icon: Icons.notifications_outlined,
        ),
        if (alerts == null || alerts.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: doc.success.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: doc.success.border),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.check_circle_outline,
                    color: doc.success.text, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.translate('report_no_alerts'),
                  style: TextStyle(fontSize: 14, color: doc.textSecondary),
                ),
              ],
            ),
          )
        else
          Column(
            children: alerts
                .map((Alert alert) => _buildAlertCard(alert, doc))
                .toList(),
          ),
        if (rec != null)
          ReportAiRecommendation(
            recommendation: rec,
          ),
      ],
    );
  }

  Widget _buildAlertCard(Alert alert, PlutusTokens doc) {
    final Color color = _severityColor(alert.severity, doc);
    final IconData icon = _severityIcon(alert.severity);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  alert.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: doc.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alert.body,
                  style: TextStyle(
                    fontSize: 12,
                    color: doc.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _severityColor(Severity severity, PlutusTokens doc) {
    switch (severity) {
      case Severity.warning:
        return doc.warning.text;
      case Severity.positive:
        return doc.success.text;
      case Severity.info:
        return doc.info.text;
    }
  }

  IconData _severityIcon(Severity severity) {
    switch (severity) {
      case Severity.warning:
        return Icons.warning_amber_rounded;
      case Severity.positive:
        return Icons.check_circle_outline;
      case Severity.info:
        return Icons.info_outline;
    }
  }
}
