import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/insights_provider.dart';
import '../../models/ai/insight.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';
import '../chart_theme.dart';
import '../glass_container.dart';

class CashFlowForecastWidget extends StatelessWidget {
  const CashFlowForecastWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final InsightsProvider provider = context.watch<InsightsProvider>();
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Forecast? forecast = provider.forecast;

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
                const Icon(Icons.auto_graph, size: 20, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.insightsForecastTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
      ),
    );
  }

  /// Builds the 3-scenario forecast line chart. Shared between dashboard widget
  /// and the full Insights screen forecast tab.
  static Widget buildForecastChart(BuildContext context, Forecast forecast, {bool showTooltips = true}) {
    final List<DailyProjection> data = forecast.dailyProjection;

    return LineChart(
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
                          color = AppColors.success;
                        case 1:
                          label = 'Likely';
                          color = AppColors.primary;
                        default:
                          label = 'Pess';
                          color = Colors.red;
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
            color: AppColors.success.withValues(alpha: 0.3),
            dotData: const FlDotData(show: false),
            barWidth: 1,
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.success.withValues(alpha: 0.05),
            ),
          ),
          // Likely line (primary)
          LineChartBarData(
            spots: data.asMap().entries.map((MapEntry<int, DailyProjection> e) {
              return FlSpot(e.key.toDouble(), e.value.likely);
            }).toList(),
            isCurved: true,
            color: AppColors.primary,
            dotData: const FlDotData(show: false),
            barWidth: 2,
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
          ),
          // Pessimistic line
          LineChartBarData(
            spots: data.asMap().entries.map((MapEntry<int, DailyProjection> e) {
              return FlSpot(e.key.toDouble(), e.value.pessimistic);
            }).toList(),
            isCurved: true,
            color: Colors.red.withValues(alpha: 0.3),
            dotData: const FlDotData(show: false),
            barWidth: 1,
            belowBarData: BarAreaData(
              show: true,
              color: Colors.red.withValues(alpha: 0.05),
            ),
          ),
        ],
      ),
    );
  }
}
