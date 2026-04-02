import 'package:flutter/material.dart';
import '../../models/report_config.dart';
import '../../models/report_data.dart';
import '../../models/ai/insight.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';
import 'report_section_header.dart';
import 'report_ai_recommendation.dart';

class AlertsSection extends StatelessWidget {
  final ReportDataModel data;

  const AlertsSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final List<Alert>? alerts = data.alerts;
    final SectionRecommendation? rec =
        data.recommendations[ReportSection.alerts];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const ReportSectionHeader(
          title: 'Alerts',
          icon: Icons.notifications_outlined,
        ),
        if (alerts == null || alerts.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.incomeAccent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                  color: AppColors.incomeAccent.withValues(alpha: 0.15)),
            ),
            child: const Row(
              children: <Widget>[
                Icon(Icons.check_circle_outline,
                    color: AppColors.incomeAccent, size: 18),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'No alerts for this period.',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          )
        else
          Column(
            children: alerts
                .map((Alert alert) => _buildAlertCard(alert))
                .toList(),
          ),
        if (rec != null)
          ReportAiRecommendation(
            recommendation: rec,
            accentColor: AppColors.warning,
          ),
      ],
    );
  }

  Widget _buildAlertCard(Alert alert) {
    final Color color = _severityColor(alert.severity);
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
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alert.body,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
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

  Color _severityColor(Severity severity) {
    switch (severity) {
      case Severity.warning:
        return AppColors.warning;
      case Severity.positive:
        return AppColors.incomeAccent;
      case Severity.info:
        return AppColors.primary;
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
