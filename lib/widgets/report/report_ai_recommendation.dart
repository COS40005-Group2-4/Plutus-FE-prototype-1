import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/report_data.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';
import '../../theme/plutus_tokens.dart';

class ReportAiRecommendation extends StatelessWidget {
  final SectionRecommendation recommendation;
  final Color? accentColor;

  const ReportAiRecommendation({
    super.key,
    required this.recommendation,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    const PlutusTokens doc = PlutusTokens.dark;
    final Color accent = accentColor ?? doc.goldText;
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      decoration: BoxDecoration(
        color: doc.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border(
          left: BorderSide(color: doc.goldText, width: 2),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.auto_awesome, size: 16, color: accent),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.translate('report_ai_insight'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            recommendation.oneLiner,
            style: TextStyle(fontSize: 14, color: doc.text, height: 1.5),
          ),
          const SizedBox(height: AppSpacing.sm),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(top: 8),
              title: Text(
                l10n.translate('report_show_analysis'),
                style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w500),
              ),
              iconColor: accent,
              collapsedIconColor: accent,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: doc.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: doc.border),
                  ),
                  child: Text(
                    recommendation.detailed,
                    style: TextStyle(fontSize: 13, color: doc.textSecondary, height: 1.6),
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
