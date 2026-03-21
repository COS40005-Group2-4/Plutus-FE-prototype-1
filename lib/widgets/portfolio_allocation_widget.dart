import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/investment_model.dart';
import '../services/interfaces/i_investment_service.dart';
import '../di/service_locator.dart';
import '../providers/auth_provider.dart';
import 'glass_container.dart';
import 'chart_theme.dart';

class PortfolioAllocationWidget extends StatefulWidget {
  const PortfolioAllocationWidget({super.key});

  @override
  State<PortfolioAllocationWidget> createState() => _PortfolioAllocationWidgetState();
}

class _PortfolioAllocationWidgetState extends State<PortfolioAllocationWidget> {
  final IInvestmentService _service = sl<IInvestmentService>();
  List<InvestmentModel>? _investments;
  bool _isLoading = true;
  int _touchedIndex = -1;

  static const Map<AssetType, Color> _assetColors = {
    AssetType.stock: Color(0xFF4285F4),
    AssetType.bond: Color(0xFF34A853),
    AssetType.crypto: Color(0xFFF39C12),
    AssetType.other: Color(0xFF95A5A6),
  };

  static const Map<AssetType, String> _assetLabels = {
    AssetType.stock: 'Stock',
    AssetType.bond: 'Bond',
    AssetType.crypto: 'Crypto',
    AssetType.other: 'Other',
  };

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUserId != null) {
      _service.setUserId(authProvider.currentUserId!);
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
    return GlassContainer(
      color: const Color(0xFF4285F4),
      opacity: 0.2,
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Portfolio Allocation',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white70, size: 18),
                onPressed: _loadData,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (_investments == null || _investments!.isEmpty) {
      return const Center(
        child: Text('No investments yet', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
      return const Center(
        child: Text('No portfolio value', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
                    PieChart(
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
                            color: _assetColors[entries[i].key] ?? PlutusChartColors.get(i),
                            value: entries[i].value,
                            title: isTouched ? '${(entries[i].value / totalValue * 100).toStringAsFixed(0)}%' : '',
                            radius: isTouched ? 38 : 30,
                            titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          );
                        }),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          PlutusChartStyle.formatCompactCurrency(totalValue),
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const Text('Total', style: TextStyle(color: Colors.white54, fontSize: 9)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...entries.map((entry) {
                final pct = (entry.value / totalValue * 100).toStringAsFixed(1);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: _assetColors[entry.key],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _assetLabels[entry.key] ?? 'Other',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                      Text('$pct%', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      const SizedBox(width: 8),
                      Text(
                        PlutusChartStyle.formatCompactCurrency(entry.value),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
