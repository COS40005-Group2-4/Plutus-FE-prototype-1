import 'package:flutter/material.dart';
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
    final List<CoachingTip>? tips = data.coachingTips;
    final SectionRecommendation? rec =
        data.recommendations[ReportSection.coaching];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const ReportSectionHeader(
          title: 'Financial Coaching',
          icon: Icons.school_outlined,
        ),
        if (tips == null || tips.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
              child: Text(
                'No coaching tips available',
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ),
          )
        else
          Column(
            children: tips
                .map((CoachingTip tip) => _buildTipCard(tip))
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

  Widget _buildTipCard(CoachingTip tip) {
    final Color diffColor = _difficultyColor(tip.difficulty);
    final String diffLabel = _difficultyLabel(tip.difficulty);

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
                const SizedBox(width: 4),
                Text(
                  'Potential savings: ${tip.savingsEstimate!.toStringAsFixed(0)}/mo',
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

  String _difficultyLabel(CoachingDifficulty difficulty) {
    switch (difficulty) {
      case CoachingDifficulty.easy:
        return 'EASY';
      case CoachingDifficulty.medium:
        return 'MEDIUM';
      case CoachingDifficulty.hard:
        return 'HARD';
    }
  }
}
