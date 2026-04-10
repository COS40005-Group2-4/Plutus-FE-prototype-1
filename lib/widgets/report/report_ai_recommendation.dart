import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/report_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';

class ReportAiRecommendation extends StatelessWidget {
  final SectionRecommendation recommendation;
  final Color accentColor;

  const ReportAiRecommendation({
    super.key,
    required this.recommendation,
    this.accentColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            accentColor.withValues(alpha: 0.08),
            accentColor.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.auto_awesome, size: 16, color: accentColor),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.translate('report_ai_insight'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.oneLiner,
            style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.5),
          ),
          const SizedBox(height: 8),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(top: 8),
              title: Text(
                l10n.translate('report_show_analysis'),
                style: TextStyle(fontSize: 12, color: accentColor, fontWeight: FontWeight.w500),
              ),
              iconColor: accentColor,
              collapsedIconColor: accentColor,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    recommendation.detailed,
                    style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
