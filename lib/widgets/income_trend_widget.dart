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

class IncomeTrendWidget extends StatefulWidget {
  const IncomeTrendWidget({super.key});

  @override
  State<IncomeTrendWidget> createState() => _IncomeTrendWidgetState();
}

class _IncomeTrendWidgetState extends State<IncomeTrendWidget> {
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
          color: const Color(0xFF34A853),
          opacity: 0.2,
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.trending_up, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Income Trend',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder<List<Transaction>>(
                  stream: _transactionService.transactionStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text('No income data', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      );
                    }
                    return _IncomeTrendContent(
                      key: ValueKey('incometrend_${settings.currency.code}'),
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

class _IncomeTrendContent extends StatefulWidget {
  final List<Transaction> transactions;
  final SettingsProvider settings;

  const _IncomeTrendContent({
    super.key,
    required this.transactions,
    required this.settings,
  });

  @override
  State<_IncomeTrendContent> createState() => _IncomeTrendContentState();
}

class _IncomeTrendContentState extends State<_IncomeTrendContent> {
  final CurrencyService _currencyService = CurrencyService();
  List<FlSpot> _spots = [];
  List<String> _labels = [];
  double _avgIncome = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _calculateIncome();
  }

  @override
  void didUpdateWidget(_IncomeTrendContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transactions != widget.transactions ||
        oldWidget.settings.currency != widget.settings.currency) {
      _calculateIncome();
    }
  }

  Future<void> _calculateIncome() async {
    setState(() => _isLoading = true);

    final targetCurrency = widget.settings.currency.code.toUpperCase();
    final Map<String, double> monthlyIncome = {};

    for (var tx in widget.transactions) {
      if (tx.isExpense) continue;
      final key = '${tx.dateTime.year}-${tx.dateTime.month.toString().padLeft(2, '0')}';

      double amount = tx.totalAmount;
      final source = tx.currency.toUpperCase();
      if (source != targetCurrency) {
        try {
          amount = await _currencyService.convert(amount: tx.totalAmount, fromCurrency: source, toCurrency: targetCurrency);
        } catch (_) {}
      }
      monthlyIncome[key] = (monthlyIncome[key] ?? 0) + amount;
    }

    final sortedKeys = monthlyIncome.keys.toList()..sort();
    // Last 12 months
    final displayKeys = sortedKeys.length > 12 ? sortedKeys.sublist(sortedKeys.length - 12) : sortedKeys;

    final spots = <FlSpot>[];
    final labels = <String>[];
    const months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

    for (int i = 0; i < displayKeys.length; i++) {
      spots.add(FlSpot(i.toDouble(), monthlyIncome[displayKeys[i]]!));
      final parts = displayKeys[i].split('-');
      labels.add(months[int.parse(parts[1]) - 1]);
    }

    final avg = spots.isNotEmpty ? spots.map((s) => s.y).reduce((a, b) => a + b) / spots.length : 0.0;

    if (mounted) {
      setState(() {
        _spots = spots;
        _labels = labels;
        _avgIncome = avg;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (_spots.length < 2) {
      return const Center(
        child: Text('Not enough income data', style: TextStyle(color: Colors.white70, fontSize: 12)),
      );
    }

    final maxY = _spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Avg: ${widget.settings.currency.symbol}${PlutusChartStyle.formatCompactCurrency(_avgIncome)}/mo',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            Text(
              'Last ${_spots.length} months',
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LineChart(
            LineChartData(
              maxY: maxY * 1.2,
              minY: 0,
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) {
                    return spots.map((spot) {
                      return LineTooltipItem(
                        _currencyService.formatCurrency(amount: spot.y, currencyCode: widget.settings.currency.code),
                        const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                      );
                    }).toList();
                  },
                ),
              ),
              gridData: PlutusChartStyle.defaultGridData(maxValue: maxY),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= _labels.length) return const SizedBox.shrink();
                      return Text(_labels[idx], style: const TextStyle(color: Colors.white54, fontSize: 9));
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
              borderData: PlutusChartStyle.lineBorderData(),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: _avgIncome,
                    color: Colors.white.withOpacity(0.3),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ],
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: _spots,
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 3,
                        color: Colors.green,
                        strokeWidth: 1,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.green.withOpacity(0.25),
                        Colors.green.withOpacity(0.02),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
