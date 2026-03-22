import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../transaction_service.dart';
import '../models/transaction_model.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../services/currency_service.dart';
import 'glass_container.dart';
import 'chart_theme.dart';

class SpendingHeatmapWidget extends StatefulWidget {
  const SpendingHeatmapWidget({super.key});

  @override
  State<SpendingHeatmapWidget> createState() => _SpendingHeatmapWidgetState();
}

class _SpendingHeatmapWidgetState extends State<SpendingHeatmapWidget> {
  late TransactionService _transactionService;

  @override
  void initState() {
    super.initState();
    _transactionService = TransactionService();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUserId != null) {
      _transactionService.setCurrentUser(authProvider.currentUserId!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _transactionService.notifyTransactionUpdate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return GlassContainer(
          color: const Color(0xFF48C9B0),
          opacity: 0.2,
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.calendar_view_week, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Spending by Day',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<List<Transaction>>(
                  stream: _transactionService.transactionStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text('No spending data', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      );
                    }
                    return _HeatmapContent(
                      key: ValueKey('heatmap_${settings.currency.code}'),
                      transactions: snapshot.data!,
                      settings: settings,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeatmapContent extends StatefulWidget {
  final List<Transaction> transactions;
  final SettingsProvider settings;

  const _HeatmapContent({
    super.key,
    required this.transactions,
    required this.settings,
  });

  @override
  State<_HeatmapContent> createState() => _HeatmapContentState();
}

class _HeatmapContentState extends State<_HeatmapContent> {
  final CurrencyService _currencyService = CurrencyService();
  Map<int, double> _weekdayAverages = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _calculateAverages();
  }

  @override
  void didUpdateWidget(_HeatmapContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transactions != widget.transactions) {
      _calculateAverages();
    }
  }

  Future<void> _calculateAverages() async {
    setState(() => _isLoading = true);

    final Map<int, List<double>> weekdayAmounts = {};
    for (int i = 1; i <= 7; i++) {
      weekdayAmounts[i] = [];
    }

    // Group expenses by day-of-week
    final Map<String, Map<int, double>> dailyByWeekday = {};
    for (var tx in widget.transactions) {
      if (!tx.isExpense) continue;
      final weekday = tx.dateTime.weekday;
      final dayKey = '${tx.dateTime.year}-${tx.dateTime.month}-${tx.dateTime.day}';

      dailyByWeekday[dayKey] ??= {};
      double amount = tx.totalAmount;
      final source = tx.currency.toUpperCase();
      final target = widget.settings.currency.code.toUpperCase();
      if (source != target) {
        try {
          amount = await _currencyService.convert(amount: tx.totalAmount, fromCurrency: source, toCurrency: target);
        } catch (_) {}
      }
      dailyByWeekday[dayKey]![weekday] = (dailyByWeekday[dayKey]![weekday] ?? 0) + amount;
    }

    // Calculate averages per weekday
    final Map<int, double> totals = {};
    final Map<int, int> counts = {};
    for (var dayEntry in dailyByWeekday.entries) {
      for (var wdEntry in dayEntry.value.entries) {
        totals[wdEntry.key] = (totals[wdEntry.key] ?? 0) + wdEntry.value;
        counts[wdEntry.key] = (counts[wdEntry.key] ?? 0) + 1;
      }
    }

    final averages = <int, double>{};
    for (int i = 1; i <= 7; i++) {
      averages[i] = counts[i] != null && counts[i]! > 0 ? totals[i]! / counts[i]! : 0;
    }

    if (mounted) {
      setState(() {
        _weekdayAverages = averages;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    final maxVal = _weekdayAverages.values.fold(0.0, (a, b) => a > b ? a : b);
    if (maxVal == 0) {
      return const Center(
        child: Text('No expense data', style: TextStyle(color: Colors.white70, fontSize: 12)),
      );
    }

    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal * 1.2,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${dayLabels[group.x]}\n${_currencyService.formatCurrency(amount: rod.toY, currencyCode: widget.settings.currency.code)}',
                const TextStyle(color: Colors.white, fontSize: 10),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= dayLabels.length) return const SizedBox.shrink();
                return Text(dayLabels[idx], style: const TextStyle(color: Colors.white70, fontSize: 10));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  PlutusChartStyle.formatCompactCurrency(value),
                  style: const TextStyle(color: Colors.white54, fontSize: 8),
                );
              },
            ),
          ),
          topTitles: PlutusChartStyle.hiddenAxisTitles(),
          rightTitles: PlutusChartStyle.hiddenAxisTitles(),
        ),
        gridData: PlutusChartStyle.defaultGridData(maxValue: maxVal),
        borderData: PlutusChartStyle.defaultBorderData(),
        barGroups: List.generate(7, (i) {
          final weekday = i + 1; // 1=Mon to 7=Sun
          final value = _weekdayAverages[weekday] ?? 0;
          final intensity = maxVal > 0 ? (value / maxVal) : 0.0;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: value,
                color: Color.lerp(
                  const Color(0xFF48C9B0).withOpacity(0.4),
                  const Color(0xFFE74C3C).withOpacity(0.9),
                  intensity,
                ),
                width: 24,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
