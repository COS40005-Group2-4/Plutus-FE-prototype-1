import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/insights_notifier.dart';
import '../../models/ai/insight.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';
import '../glass_container.dart';

class InsightsFeedWidget extends ConsumerWidget {
  const InsightsFeedWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final InsightsState provider = ref.watch(insightsNotifierProvider);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<SpendingInsight> insights = provider.spendingInsights.take(3).toList();

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
                const Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.translate('widget_label_insights_feed'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(width: AppSpacing.xs),
                Tooltip(
                  message: l10n.widgetHelpInsightsFeed,
                  child: Icon(
                    Icons.help_outline,
                    size: 14,
                    color: AppColors.textTertiary(Theme.of(context).brightness),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (provider.isGenerating)
              const Expanded(
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (insights.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    l10n.insightsEmptySubtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: insights.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (BuildContext context, int index) {
                    final SpendingInsight insight = insights[index];
                    return Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                        borderRadius: AppRadius.borderSm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            insight.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: (provider.insightsFontSize - 1).clamp(11.0, 18.0),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            insight.body,
                            style: TextStyle(
                              fontSize: (provider.insightsFontSize - 2).clamp(10.0, 16.0),
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            // Import banner within widget
            if (provider.showImportBanner) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadius.borderSm,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.new_releases, size: 14, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        l10n.insightsImportBannerAction,
                        style: const TextStyle(fontSize: 11, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
