import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/insights_notifier.dart';
import '../../models/ai/insight.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';
import '../../theme/plutus_tokens.dart';
import '../chart_theme.dart';

class CoachingTipsWidget extends ConsumerStatefulWidget {
  const CoachingTipsWidget({super.key});

  @override
  ConsumerState<CoachingTipsWidget> createState() => _CoachingTipsWidgetState();
}

class _CoachingTipsWidgetState extends ConsumerState<CoachingTipsWidget> {
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
      final InsightsState provider = ref.read(insightsNotifierProvider);
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
    final InsightsState provider = ref.watch(insightsNotifierProvider);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final PlutusTokens t = context.tokens;
    final List<CoachingTip> tips = provider.coachingTips;

    if (_currentIndex >= tips.length) {
      _currentIndex = 0;
    }

    // Locked design call #2: coaching cards are always the info quartet.
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/insights'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: t.info.surface,
          borderRadius: AppRadius.borderCard,
          border: Border.all(color: t.info.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, size: 20, color: t.info.text),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.translate('widget_label_coaching_tips'),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: t.info.text),
                ),
                const SizedBox(width: AppSpacing.xs),
                Tooltip(
                  message: l10n.widgetHelpCoachingTips,
                  child: Icon(
                    Icons.help_outline,
                    size: 14,
                    color: t.textMuted,
                  ),
                ),
                const Spacer(),
                if (tips.length > 1)
                  Text(
                    '${_currentIndex + 1}/${tips.length}',
                    style: TextStyle(
                      fontSize: 11,
                      color: t.textMuted,
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
                              color: t.textMuted,
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

  Widget _buildTipCard(BuildContext context, CoachingTip tip, InsightsState provider, AppLocalizations l10n) {
    final PlutusTokens t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tip.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: (provider.insightsFontSize - 1).clamp(11.0, 18.0),
            color: t.info.text,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        Expanded(
          child: Text(
            tip.body,
            style: TextStyle(
              fontSize: (provider.insightsFontSize - 2).clamp(10.0, 16.0),
              color: t.text,
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
                Icon(Icons.savings_outlined, size: 14, color: t.success.text),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  PlutusChartStyle.formatCompactCurrency(tip.savingsEstimate!),
                  style: TextStyle(fontSize: 11, color: t.success.text, fontWeight: FontWeight.w600),
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
                onPressed: () => ref.read(insightsNotifierProvider.notifier).saveCoachingTip(tip.id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: t.goldText,
              ),
            if (tip.isSaved)
              Icon(Icons.bookmark, size: 18, color: t.goldText),
          ],
        ),
      ],
    );
  }

}
