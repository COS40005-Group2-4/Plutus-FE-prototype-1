import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/investment_model.dart';
import '../services/interfaces/i_investment_service.dart';
import '../di/service_locator.dart';
import '../providers/auth_notifier.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_spacing.dart';
import '../theme/plutus_tokens.dart';
import 'core/app_card.dart';
import 'chart_theme.dart';

class PortfolioAllocationWidget extends ConsumerStatefulWidget {
  const PortfolioAllocationWidget({super.key});

  @override
  ConsumerState<PortfolioAllocationWidget> createState() => _PortfolioAllocationWidgetState();
}

class _PortfolioAllocationWidgetState extends ConsumerState<PortfolioAllocationWidget> {
  final IInvestmentService _service = sl<IInvestmentService>();
  List<InvestmentModel>? _investments;
  bool _isLoading = true;
  int _touchedIndex = -1;

  static const Map<AssetType, String> _assetLabels = {
    AssetType.stock: 'Stock',
    AssetType.bond: 'Bond',
    AssetType.crypto: 'Crypto',
    AssetType.other: 'Other',
  };

  @override
  void initState() {
    super.initState();
    final currentUserId = ref.read(authNotifierProvider.notifier).currentUserId;
    if (currentUserId != null) {
      _service.setUserId(currentUserId);
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final investments = await _service.getInvestmentList();
      if (mounted) {
        setState(() {
          _investments = investments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final PlutusTokens t = context.tokens;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                    Row(
                      children: [
                        Text(
                          'Portfolio Allocation',
                          style: TextStyle(color: t.text, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Tooltip(
                          message: AppLocalizations.of(context).widgetHelpPortfolioAllocation,
                          child: Icon(
                            Icons.help_outline,
                            size: 14,
                            color: t.textMuted,
                          ),
                        ),
                      ],
                    ),
              IconButton(
                icon: Icon(Icons.refresh, color: t.textSecondary, size: 18),
                onPressed: _loadData,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final PlutusTokens t = context.tokens;
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: t.text));
    }

    if (_investments == null || _investments!.isEmpty) {
      return Center(
        child: Text('No investments yet', style: TextStyle(color: t.textSecondary, fontSize: 12)),
      );
    }

    // Group by asset type
    final Map<AssetType, double> allocation = {};
    for (var inv in _investments!) {
      final value = inv.getCurrentValue();
      allocation[inv.assetType] = (allocation[inv.assetType] ?? 0) + value;
    }

    final totalValue = allocation.values.fold(0.0, (sum, v) => sum + v);
    if (totalValue == 0) {
      return Center(
        child: Text('No portfolio value', style: TextStyle(color: t.textSecondary, fontSize: 12)),
      );
    }

    final entries = allocation.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: (constraints.maxHeight * 0.55).clamp(100.0, 160.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    RepaintBoundary(
                      child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                _touchedIndex = -1;
                                return;
                              }
                              _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 2,
                        centerSpaceRadius: 35,
                        sections: List.generate(entries.length, (i) {
                          final isTouched = i == _touchedIndex;
                          return PieChartSectionData(
                            color: t.chartCategorical[i % 6],
                            value: entries[i].value,
                            title: isTouched ? '${(entries[i].value / totalValue * 100).toStringAsFixed(0)}%' : '',
                            radius: isTouched ? 38 : 30,
                            titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          );
                        }),
                      ),
                    ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          PlutusChartStyle.formatCompactCurrency(totalValue),
                          style: TextStyle(color: t.text, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text('Total', style: TextStyle(color: t.textSecondary, fontSize: 9)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...entries.asMap().entries.map((mapEntry) {
                final i = mapEntry.key;
                final entry = mapEntry.value;
                final pct = (entry.value / totalValue * 100).toStringAsFixed(1);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: t.chartCategorical[i % 6],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _assetLabels[entry.key] ?? 'Other',
                          style: TextStyle(color: t.textSecondary, fontSize: 12),
                        ),
                      ),
                      Text('$pct%', style: TextStyle(color: t.textSecondary, fontSize: 11)),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        PlutusChartStyle.formatCompactCurrency(entry.value),
                        style: TextStyle(color: t.text, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
