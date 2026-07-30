import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/insights_notifier.dart';
import '../../models/ai/insight.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';
import '../../theme/plutus_tokens.dart';
import '../core/app_card.dart';

class InsightsFeedWidget extends ConsumerWidget {
  const InsightsFeedWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final InsightsState provider = ref.watch(insightsNotifierProvider);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final PlutusTokens t = context.tokens;
    final List<SpendingInsight> insights = provider.spendingInsights.take(3).toList();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => Navigator.pushNamed(context, '/insights'),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: t.brandNavy, size: 20),
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
                    color: t.textMuted,
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
                        color: t.surfaceSubtle,
                        borderRadius: AppRadius.borderSm,
                        border: Border.all(color: t.border),
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
                              color: t.textSecondary,
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
                  color: t.info.surface,
                  borderRadius: AppRadius.borderSm,
                  border: Border.all(color: t.info.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.new_releases, size: 14, color: t.info.text),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        l10n.insightsImportBannerAction,
                        style: TextStyle(fontSize: 11, color: t.info.text),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
    );
  }
}
