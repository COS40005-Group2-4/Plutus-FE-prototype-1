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

class CoachingSection extends StatelessWidget {
  final ReportDataModel data;

  const CoachingSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<CoachingTip>? tips = data.coachingTips;
    final SectionRecommendation? rec =
        data.recommendations[ReportSection.coaching];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ReportSectionHeader(
          title: l10n.translate('report_financial_coaching'),
          icon: Icons.school_outlined,
        ),
        if (tips == null || tips.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
              child: Text(
                l10n.translate('report_no_coaching'),
                style: const TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ),
          )
        else
          Column(
            children: tips
                .map((CoachingTip tip) => _buildTipCard(tip, l10n))
                .toList(),
          ),
        if (rec != null)
          ReportAiRecommendation(
            recommendation: rec,
            accentColor: AppColors.primary,
          ),
      ],
    );
  }

  Widget _buildTipCard(CoachingTip tip, AppLocalizations l10n) {
    final Color diffColor = _difficultyColor(tip.difficulty);
    final String diffLabel = _difficultyLabel(tip.difficulty, l10n);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  tip.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: diffColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  diffLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: diffColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            tip.body,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white54,
              height: 1.5,
            ),
          ),
          if (tip.savingsEstimate != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: <Widget>[
                const Icon(
                  Icons.savings_outlined,
                  size: 14,
                  color: AppColors.savingsAccent,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${l10n.translate('report_potential_savings')}${tip.savingsEstimate!.toStringAsFixed(0)}${l10n.translate('report_per_month')}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.savingsAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _difficultyColor(CoachingDifficulty difficulty) {
    switch (difficulty) {
      case CoachingDifficulty.easy:
        return AppColors.incomeAccent;
      case CoachingDifficulty.medium:
        return AppColors.warning;
      case CoachingDifficulty.hard:
        return AppColors.expenseAccent;
    }
  }

  String _difficultyLabel(CoachingDifficulty difficulty, AppLocalizations l10n) {
    switch (difficulty) {
      case CoachingDifficulty.easy:
        return l10n.translate('report_difficulty_easy');
      case CoachingDifficulty.medium:
        return l10n.translate('report_difficulty_medium');
      case CoachingDifficulty.hard:
        return l10n.translate('report_difficulty_hard');
    }
  }
}
