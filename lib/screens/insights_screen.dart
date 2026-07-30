import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/insights_notifier.dart';
import '../router/app_router.dart';
import '../models/ai/insight.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';
import '../theme/plutus_tokens.dart';
import '../widgets/chart_theme.dart';
import '../widgets/core/app_card.dart';
import '../widgets/core/status_badge.dart';
import '../widgets/insights/cash_flow_forecast_widget.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final InsightsState provider = ref.watch(insightsNotifierProvider);
    final insightsNotifier = ref.read(insightsNotifierProvider.notifier);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final PlutusTokens t = context.tokens;
    // t.brandNavy inverts brightness role between themes (dark navy in light
    // mode, pale blue-grey in dark mode) — the FAB ink must invert with it.
    final Color fabInk = Theme.of(context).brightness == Brightness.dark ? t.onGold : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.insightsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.insightsTabSpending),
            Tab(text: l10n.insightsTabForecast),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.insightsTabAlerts),
                  if (provider.unreadAlertCount > 0) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: t.error.dot,
                        borderRadius: AppRadius.borderMd,
                      ),
                      child: Text(
                        '${provider.unreadAlertCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(text: l10n.insightsTabCoaching),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FloatingActionButton.small(
            heroTag: 'font_increase',
            onPressed: provider.canIncreaseFontSize ? insightsNotifier.increaseFontSize : null,
            backgroundColor: provider.canIncreaseFontSize
                ? t.brandNavy
                : t.brandNavy.withValues(alpha: 0.3),
            tooltip: l10n.textSizeIncrease,
            child: Text('A+', style: TextStyle(color: fabInk, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(height: AppSpacing.sm),
          FloatingActionButton.small(
            heroTag: 'font_decrease',
            onPressed: provider.canDecreaseFontSize ? insightsNotifier.decreaseFontSize : null,
            backgroundColor: provider.canDecreaseFontSize
                ? t.brandNavy
                : t.brandNavy.withValues(alpha: 0.3),
            tooltip: l10n.textSizeDecrease,
            child: Text('A−', style: TextStyle(color: fabInk, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Import banner
          if (provider.showImportBanner)
            _buildImportBanner(context, provider, insightsNotifier, l10n),
          // Period selector
          _buildPeriodBar(context, provider, insightsNotifier, l10n),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SpendingTab(provider: provider, l10n: l10n),
                _ForecastTab(provider: provider, l10n: l10n),
                _AlertsTab(provider: provider, insightsNotifier: insightsNotifier, l10n: l10n),
                _CoachingTab(provider: provider, insightsNotifier: insightsNotifier, l10n: l10n),
              ],
            ),
          ),
          // Generate button
          _buildGenerateButton(context, provider, insightsNotifier, l10n),
        ],
      ),
    );
  }

  Widget _buildImportBanner(BuildContext context, InsightsState provider, InsightsNotifier insightsNotifier, AppLocalizations l10n) {
    final PlutusTokens t = context.tokens;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: t.info.surface,
        border: Border(bottom: BorderSide(color: t.info.border)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: t.info.text, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.insightsImportBanner,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => insightsNotifier.generateInsights(),
            child: Text(l10n.insightsImportBannerAction),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => insightsNotifier.dismissImportBanner(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodBar(BuildContext context, InsightsState provider, InsightsNotifier insightsNotifier, AppLocalizations l10n) {
    final PlutusTokens t = context.tokens;
    final List<({int months, String label})> presets = <({int months, String label})>[
      (months: 1, label: l10n.insightsPeriod1m),
      (months: 3, label: l10n.insightsPeriod3m),
      (months: 6, label: l10n.insightsPeriod6m),
      (months: 12, label: l10n.insightsPeriod1y),
    ];

    return Container(
      height: 44,
      color: Colors.transparent,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        children: <Widget>[
          ...presets.map((preset) {
            final bool selected = !provider.hasCustomDateRange &&
                provider.selectedPeriodMonths == preset.months;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: ChoiceChip(
                label: Text(preset.label),
                selected: selected,
                onSelected: (_) => insightsNotifier.setSelectedPeriod(preset.months),
                selectedColor: t.goldSelectedFill,
                labelStyle: TextStyle(
                  color: t.text,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            );
          }),
          // Custom date range chip
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: ChoiceChip(
              avatar: const Icon(Icons.date_range, size: 14),
              label: Text(
                provider.hasCustomDateRange
                    ? _formatCustomRange(provider.customStartDate!, provider.customEndDate!)
                    : l10n.insightsPeriodCustom,
              ),
              selected: provider.hasCustomDateRange,
              onSelected: (_) => _pickCustomRange(context, provider, insightsNotifier),
              selectedColor: t.goldSelectedFill,
              labelStyle: TextStyle(
                color: t.text,
                fontSize: 12,
                fontWeight: provider.hasCustomDateRange ? FontWeight.w600 : FontWeight.normal,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCustomRange(DateTime start, DateTime end) {
    final String s = '${start.day}/${start.month}';
    final String e = '${end.day}/${end.month}';
    return '$s–$e';
  }

  Future<void> _pickCustomRange(BuildContext context, InsightsState provider, InsightsNotifier insightsNotifier) async {
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: provider.hasCustomDateRange
          ? DateTimeRange(start: provider.customStartDate!, end: provider.customEndDate!)
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 90)),
              end: DateTime.now(),
            ),
    );
    if (range != null) {
      insightsNotifier.setCustomDateRange(range.start, range.end);
    }
  }

  Widget _buildGenerateButton(BuildContext context, InsightsState provider, InsightsNotifier insightsNotifier, AppLocalizations l10n) {
    final PlutusTokens t = context.tokens;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: provider.isGenerating ? null : () => insightsNotifier.generateInsights(),
              icon: provider.isGenerating
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome),
              label: Text(provider.isGenerating ? l10n.insightsGenerating : l10n.insightsGenerate),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (provider.lastGenerated != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${l10n.insightsLastGenerated}: ${_formatTime(provider.lastGenerated!)}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
          if (provider.error != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.insightsError,
              style: TextStyle(fontSize: 12, color: t.error.text),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final String day = dt.day.toString().padLeft(2, '0');
    final String month = dt.month.toString().padLeft(2, '0');
    final String hour = dt.hour.toString().padLeft(2, '0');
    final String minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }
}

// ── Spending Tab ──
class _SpendingTab extends StatelessWidget {
  final InsightsState provider;
  final AppLocalizations l10n;

  const _SpendingTab({required this.provider, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final List<SpendingInsight> insights = provider.spendingInsights;
    if (insights.isEmpty) {
      return _EmptyState(
        icon: Icons.analytics_outlined,
        title: l10n.insightsEmpty,
        subtitle: l10n.insightsEmptySubtitle,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: insights.length,
      itemBuilder: (BuildContext context, int index) {
        final SpendingInsight insight = insights[index];
        return _InsightCard(
          title: insight.title,
          body: insight.body,
          category: insight.category,
          metric: insight.metric,
          fontSize: provider.insightsFontSize,
        );
      },
    );
  }
}

// ── Forecast Tab ──
class _ForecastTab extends StatelessWidget {
  final InsightsState provider;
  final AppLocalizations l10n;

  const _ForecastTab({required this.provider, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final PlutusTokens t = context.tokens;
    final Forecast? forecast = provider.forecast;
    if (forecast == null) {
      return _EmptyState(
        icon: Icons.auto_graph,
        title: l10n.insightsForecastEmpty,
        subtitle: l10n.insightsEmptySubtitle,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.insightsForecastTitle,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(forecast.summary, style: TextStyle(fontSize: provider.insightsFontSize)),
                const SizedBox(height: AppSpacing.md),
                // Projected balance breakdown — colors mirror the 3-scenario
                // forecast chart palette (chartCategorical roles), not status
                // severity: these are chart series, not warnings/errors.
                _ForecastRow(
                  label: l10n.insightsForecastOptimistic,
                  value: forecast.projectedBalance['optimistic'] ?? 0,
                  color: t.chartCategorical[1],
                ),
                const SizedBox(height: AppSpacing.xs),
                _ForecastRow(
                  label: l10n.insightsForecastLikely,
                  value: forecast.projectedBalance['likely'] ?? 0,
                  color: t.chartCategorical[0],
                ),
                const SizedBox(height: AppSpacing.xs),
                _ForecastRow(
                  label: l10n.insightsForecastPessimistic,
                  value: forecast.projectedBalance['pessimistic'] ?? 0,
                  color: t.chartCategorical[3],
                ),
              ],
            ),
          ),
          if (forecast.dailyProjection.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                height: 200,
                child: CashFlowForecastWidget.buildForecastChart(context, forecast),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ForecastRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _ForecastRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
        Text(
          PlutusChartStyle.formatCompactCurrency(value),
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}

// ── Alerts Tab ──
class _AlertsTab extends StatelessWidget {
  final InsightsState provider;
  final InsightsNotifier insightsNotifier;
  final AppLocalizations l10n;

  const _AlertsTab({required this.provider, required this.insightsNotifier, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final List<Alert> alerts = provider.alerts;
    if (alerts.isEmpty) {
      return _EmptyState(
        icon: Icons.notifications_none,
        title: l10n.insightsAlertsEmpty,
        subtitle: l10n.insightsEmptySubtitle,
      );
    }

    return Column(
      children: [
        if (provider.unreadAlertCount > 0)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md, top: AppSpacing.sm),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => insightsNotifier.markAllAlertsRead(),
                child: Text(l10n.insightsAlertsMarkRead),
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: alerts.length,
            itemBuilder: (BuildContext context, int index) {
              final Alert alert = alerts[index];
              return _AlertCard(
                alert: alert,
                fontSize: provider.insightsFontSize,
                onTap: () => insightsNotifier.markAlertRead(alert.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Alert alert;
  final double fontSize;
  final VoidCallback onTap;

  const _AlertCard({required this.alert, required this.fontSize, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final PlutusTokens t = context.tokens;
    // Alert.severity has no "error" level (info/warning/positive) — map the
    // real three values onto the matching quartet arms.
    final StatusColors severity = alert.severity == Severity.warning
        ? t.warning
        : alert.severity == Severity.positive
            ? t.success
            : t.info;
    final Color cardColor = alert.isRead ? t.surfaceSubtle : severity.surface;
    final Color cardBorder = alert.isRead ? t.border : severity.border;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: AppRadius.borderLg,
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                alert.severity == Severity.warning
                    ? Icons.warning_amber_rounded
                    : alert.severity == Severity.positive
                        ? Icons.thumb_up_alt_outlined
                        : Icons.info_outline,
                color: severity.text,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: TextStyle(
                        fontWeight: alert.isRead ? FontWeight.normal : FontWeight.bold,
                        fontSize: fontSize + 1,
                        color: t.text,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      alert.body,
                      style: TextStyle(
                        fontSize: fontSize,
                        color: t.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!alert.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: severity.dot, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Coaching Tab ──
class _CoachingTab extends StatelessWidget {
  final InsightsState provider;
  final InsightsNotifier insightsNotifier;
  final AppLocalizations l10n;

  const _CoachingTab({required this.provider, required this.insightsNotifier, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final List<CoachingTip> tips = provider.coachingTips;
    if (tips.isEmpty) {
      return _EmptyState(
        icon: Icons.school_outlined,
        title: l10n.insightsCoachingEmpty,
        subtitle: l10n.insightsEmptySubtitle,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: tips.length,
      itemBuilder: (BuildContext context, int index) {
        final CoachingTip tip = tips[index];
        return _CoachingCard(
          tip: tip,
          l10n: l10n,
          fontSize: provider.insightsFontSize,
          onSave: () => insightsNotifier.saveCoachingTip(tip.id),
          onDismiss: () => insightsNotifier.dismissCoachingTip(tip.id),
        );
      },
    );
  }
}

class _CoachingCard extends StatelessWidget {
  final CoachingTip tip;
  final AppLocalizations l10n;
  final double fontSize;
  final VoidCallback onSave;
  final VoidCallback onDismiss;

  const _CoachingCard({
    required this.tip,
    required this.l10n,
    required this.fontSize,
    required this.onSave,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final PlutusTokens t = context.tokens;
    // Locked design call #2: coaching cards are always the info quartet
    // (card surface, not the difficulty badge below).
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: t.info.surface,
          borderRadius: AppRadius.borderLg,
          border: Border.all(color: t.info.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tip.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize + 1,
                      color: t.info.text,
                    ),
                  ),
                ),
                _DifficultyBadge(difficulty: tip.difficulty, l10n: l10n),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(tip.body, style: TextStyle(fontSize: fontSize, color: t.text)),
            if (tip.savingsEstimate != null && tip.savingsEstimate! > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(Icons.savings_outlined, size: 16, color: t.success.text),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${l10n.insightsCoachingPotentialSavings}: ${PlutusChartStyle.formatCompactCurrency(tip.savingsEstimate!)}',
                    style: TextStyle(fontSize: 12, color: t.success.text, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onDismiss,
                  child: Text(l10n.insightsCoachingDismiss),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (!tip.isSaved)
                  ElevatedButton.icon(
                    onPressed: onSave,
                    icon: const Icon(Icons.bookmark_border, size: 16),
                    label: Text(l10n.insightsCoachingSave),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  )
                else
                  Icon(Icons.bookmark, color: t.goldText, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

}

class _DifficultyBadge extends StatelessWidget {
  final CoachingDifficulty difficulty;
  final AppLocalizations l10n;

  const _DifficultyBadge({required this.difficulty, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final StatusKind kind;
    final String label;
    switch (difficulty) {
      case CoachingDifficulty.easy:
        kind = StatusKind.success;
        label = l10n.translate('insights_coaching_difficulty_easy');
      case CoachingDifficulty.medium:
        kind = StatusKind.warning;
        label = l10n.translate('insights_coaching_difficulty_medium');
      case CoachingDifficulty.hard:
        kind = StatusKind.error;
        label = l10n.translate('insights_coaching_difficulty_hard');
    }

    return StatusBadge(kind: kind, label: label);
  }
}

// ── Shared Components ──

class _InsightCard extends StatelessWidget {
  final String title;
  final String body;
  final String? category;
  final InsightMetric? metric;
  final double fontSize;

  const _InsightCard({
    required this.title,
    required this.body,
    this.category,
    this.metric,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final PlutusTokens t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (category != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: t.brandNavy.withValues(alpha: 0.12),
                      borderRadius: AppRadius.borderMd,
                    ),
                    child: Text(
                      category!,
                      style: TextStyle(fontSize: 11, color: t.brandNavy),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                const Spacer(),
                if (metric != null) _MetricBadge(metric: metric!),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize + 1)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              body,
              style: TextStyle(
                fontSize: fontSize,
                color: t.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  final InsightMetric metric;

  const _MetricBadge({required this.metric});

  @override
  Widget build(BuildContext context) {
    final PlutusTokens t = context.tokens;
    // InsightMetric.severity has no "error" level (info/warning/positive) —
    // map the real three values onto the matching quartet arms.
    final StatusColors severity = metric.severity == Severity.warning
        ? t.warning
        : metric.severity == Severity.positive
            ? t.success
            : t.info;

    final IconData icon = metric.direction == 'up'
        ? Icons.trending_up
        : metric.direction == 'down'
            ? Icons.trending_down
            : Icons.trending_flat;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: severity.surface,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: severity.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: severity.text),
          const SizedBox(width: 2),
          Text(metric.label, style: TextStyle(fontSize: 11, color: severity.text, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
