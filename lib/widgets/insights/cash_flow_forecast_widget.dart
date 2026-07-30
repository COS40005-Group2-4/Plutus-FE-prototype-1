import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/insights_notifier.dart';
import '../../models/ai/insight.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_spacing.dart';
import '../../theme/plutus_tokens.dart';
import '../chart_theme.dart';
import '../core/app_card.dart';

class CashFlowForecastWidget extends ConsumerWidget {
  const CashFlowForecastWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final InsightsState provider = ref.watch(insightsNotifierProvider);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final PlutusTokens t = context.tokens;
    final Forecast? forecast = provider.forecast;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => Navigator.pushNamed(context, '/insights'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_graph, size: 20, color: t.brandNavy),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.insightsForecastTitle,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(width: AppSpacing.xs),
              Tooltip(
                message: l10n.widgetHelpCashflowForecast,
                child: Icon(
                  Icons.help_outline,
                  size: 14,
                  color: t.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: provider.isGenerating
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : forecast == null || forecast.dailyProjection.isEmpty
                    ? Center(
                        child: Text(
                          l10n.insightsForecastEmpty,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : buildForecastChart(context, forecast),
          ),
          if (forecast != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${l10n.insightsForecastProjected}: ${PlutusChartStyle.formatCompactCurrency(forecast.projectedBalance['likely'] ?? 0)}',
              style: TextStyle(
                fontSize: (provider.insightsFontSize - 2).clamp(10.0, 16.0),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the 3-scenario forecast line chart. Shared between dashboard widget
  /// and the full Insights screen forecast tab.
  static Widget buildForecastChart(BuildContext context, Forecast forecast, {bool showTooltips = true}) {
    final PlutusTokens t = context.tokens;
    final List<DailyProjection> data = forecast.dailyProjection;
    // Chart palette roles (spec §3.4): base/likely -> navy, optimistic ->
    // gold (the palette's one reserved projection/reference role),
    // pessimistic -> teal. Not status severity.
    final Color baseColor = t.chartCategorical[0];
    final Color optimisticColor = t.chartCategorical[1];
    final Color pessimisticColor = t.chartCategorical[3];

    return RepaintBoundary(
      child: LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: showTooltips
            ? LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (List<LineBarSpot> spots) {
                    return spots.map((LineBarSpot spot) {
                      final String label;
                      final Color color;
                      switch (spot.barIndex) {
                        case 0:
                          label = 'Opt';
                          color = optimisticColor;
                        case 1:
                          label = 'Likely';
                          color = baseColor;
                        default:
                          label = 'Pess';
                          color = pessimisticColor;
                      }
                      return LineTooltipItem(
                        '$label: ${PlutusChartStyle.formatCompactCurrency(spot.y)}',
                        TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                      );
                    }).toList();
                  },
                ),
              )
            : const LineTouchData(enabled: false),
        lineBarsData: [
          // Optimistic line
          LineChartBarData(
            spots: data.asMap().entries.map((MapEntry<int, DailyProjection> e) {
              return FlSpot(e.key.toDouble(), e.value.optimistic);
            }).toList(),
            isCurved: true,
            color: optimisticColor.withValues(alpha: 0.3),
            dotData: const FlDotData(show: false),
            barWidth: 1,
            belowBarData: BarAreaData(
              show: true,
              color: optimisticColor.withValues(alpha: 0.05),
            ),
          ),
          // Likely line (base)
          LineChartBarData(
            spots: data.asMap().entries.map((MapEntry<int, DailyProjection> e) {
              return FlSpot(e.key.toDouble(), e.value.likely);
            }).toList(),
            isCurved: true,
            color: baseColor,
            dotData: const FlDotData(show: false),
            barWidth: 2,
            belowBarData: BarAreaData(
              show: true,
              color: baseColor.withValues(alpha: 0.1),
            ),
          ),
          // Pessimistic line
          LineChartBarData(
            spots: data.asMap().entries.map((MapEntry<int, DailyProjection> e) {
              return FlSpot(e.key.toDouble(), e.value.pessimistic);
            }).toList(),
            isCurved: true,
            color: pessimisticColor.withValues(alpha: 0.3),
            dotData: const FlDotData(show: false),
            barWidth: 1,
            belowBarData: BarAreaData(
              show: true,
              color: pessimisticColor.withValues(alpha: 0.05),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
