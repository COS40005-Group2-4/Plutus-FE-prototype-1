import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/insights_provider.dart';
import '../../models/ai/insight.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';
import '../chart_theme.dart';
import '../glass_container.dart';

class CoachingTipsWidget extends StatefulWidget {
  const CoachingTipsWidget({super.key});

  @override
  State<CoachingTipsWidget> createState() => _CoachingTipsWidgetState();
}

class _CoachingTipsWidgetState extends State<CoachingTipsWidget> {
  int _currentIndex = 0;
  Timer? _rotateTimer;

  @override
  void initState() {
    super.initState();
    _startAutoRotate();
  }

  @override
  void dispose() {
    _rotateTimer?.cancel();
    super.dispose();
  }

  void _startAutoRotate() {
    _rotateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      final InsightsProvider provider = context.read<InsightsProvider>();
      final int count = provider.coachingTips.length;
      if (count > 1) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % count;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final InsightsProvider provider = context.watch<InsightsProvider>();
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<CoachingTip> tips = provider.coachingTips;

    if (_currentIndex >= tips.length) {
      _currentIndex = 0;
    }

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/insights'),
      child: GlassContainer(
        padding: const EdgeInsets.all(AppSpacing.md),
        borderRadius: AppRadius.lg,
        opacity: 0.08,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.school, size: 20, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.translate('widget_label_coaching_tips'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(width: 4),
                Tooltip(
                  message: l10n.widgetHelpCoachingTips,
                  child: Icon(
                    Icons.help_outline,
                    size: 14,
                    color: AppColors.textTertiary(Theme.of(context).brightness),
                  ),
                ),
                const Spacer(),
                if (tips.length > 1)
                  Text(
                    '${_currentIndex + 1}/${tips.length}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: provider.isGenerating
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : tips.isEmpty
                      ? Center(
                          child: Text(
                            l10n.insightsCoachingEmpty,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : _buildTipCard(context, tips[_currentIndex], provider, l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(BuildContext context, CoachingTip tip, InsightsProvider provider, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tip.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: (provider.insightsFontSize - 1).clamp(11.0, 18.0),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Text(
            tip.body,
            style: TextStyle(
              fontSize: (provider.insightsFontSize - 2).clamp(10.0, 16.0),
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (tip.savingsEstimate != null && tip.savingsEstimate! > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const Icon(Icons.savings_outlined, size: 14, color: AppColors.success),
                const SizedBox(width: 4),
                Text(
                  PlutusChartStyle.formatCompactCurrency(tip.savingsEstimate!),
                  style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (!tip.isSaved)
              IconButton(
                icon: const Icon(Icons.bookmark_border, size: 18),
                onPressed: () => provider.saveCoachingTip(tip.id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: AppColors.primary,
              ),
            if (tip.isSaved)
              const Icon(Icons.bookmark, size: 18, color: AppColors.primary),
          ],
        ),
      ],
    );
  }

}
