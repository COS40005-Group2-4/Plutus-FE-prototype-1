import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../transaction_service.dart';
import '../models/transaction_model.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../services/currency_service.dart';
import '../theme/app_colors.dart';
import 'glass_container.dart';
import 'chart_theme.dart';

class SavingsRateWidget extends StatefulWidget {
  const SavingsRateWidget({super.key});

  @override
  State<SavingsRateWidget> createState() => _SavingsRateWidgetState();
}

class _SavingsRateWidgetState extends State<SavingsRateWidget> {
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
          color: AppColors.savingsAccent,
          opacity: 0.2,
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.savings, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Savings Rate',
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
                        child: Text('No data available', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      );
                    }
                    return _SavingsRateContent(
                      key: ValueKey('savings_${settings.currency.code}'),
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

class _SavingsRateContent extends StatefulWidget {
  final List<Transaction> transactions;
  final SettingsProvider settings;

  const _SavingsRateContent({
    super.key,
    required this.transactions,
    required this.settings,
  });

  @override
  State<_SavingsRateContent> createState() => _SavingsRateContentState();
}

class _SavingsRateContentState extends State<_SavingsRateContent> {
  final CurrencyService _currencyService = CurrencyService();
  List<FlSpot> _spots = [];
  List<String> _labels = [];
  double _currentRate = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _calculateSavingsRate();
  }

  @override
  void didUpdateWidget(_SavingsRateContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transactions != widget.transactions ||
        oldWidget.settings.currency != widget.settings.currency) {
      _calculateSavingsRate();
    }
  }

  Future<void> _calculateSavingsRate() async {
    setState(() => _isLoading = true);

    final targetCurrency = widget.settings.currency.code.toUpperCase();
    final Map<String, double> monthlyIncome = {};
    final Map<String, double> monthlyExpense = {};

    for (var tx in widget.transactions) {
      final key = '${tx.dateTime.year}-${tx.dateTime.month.toString().padLeft(2, '0')}';
      double amount = tx.totalAmount;
      final source = tx.currency.toUpperCase();
      if (source != targetCurrency) {
        try {
          amount = await _currencyService.convert(amount: tx.totalAmount, fromCurrency: source, toCurrency: targetCurrency);
        } catch (_) {}
      }
      if (tx.isExpense) {
        monthlyExpense[key] = (monthlyExpense[key] ?? 0) + amount;
      } else {
        monthlyIncome[key] = (monthlyIncome[key] ?? 0) + amount;
      }
    }

    final allKeys = {...monthlyIncome.keys, ...monthlyExpense.keys}.toList()..sort();
    final displayKeys = allKeys.length > 12 ? allKeys.sublist(allKeys.length - 12) : allKeys;

    final spots = <FlSpot>[];
    final labels = <String>[];
    const months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

    for (int i = 0; i < displayKeys.length; i++) {
      final income = monthlyIncome[displayKeys[i]] ?? 0;
      final expense = monthlyExpense[displayKeys[i]] ?? 0;
      final rate = income > 0 ? ((income - expense) / income * 100).clamp(-100.0, 100.0) : 0.0;
      spots.add(FlSpot(i.toDouble(), rate));
      final parts = displayKeys[i].split('-');
      labels.add(months[int.parse(parts[1]) - 1]);
    }

    final currentRate = spots.isNotEmpty ? spots.last.y : 0.0;

    if (mounted) {
      setState(() {
        _spots = spots;
        _labels = labels;
        _currentRate = currentRate;
        _isLoading = false;
      });
    }
  }

  Color _getRateColor(double rate, Brightness brightness) {
    if (rate >= 20) return AppColors.positive(brightness);
    if (rate >= 10) return Colors.orange;
    return AppColors.negative(brightness);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    final brightness = Theme.of(context).brightness;
    final rateColor = _getRateColor(_currentRate, brightness);

    return Column(
      children: [
        // Current savings rate
        GlassContainer(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          opacity: 0.1,
          borderRadius: 8,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${_currentRate.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: rateColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('This Month', style: TextStyle(color: Colors.white54, fontSize: 10)),
                  Text(
                    _currentRate >= 20 ? 'Great!' : _currentRate >= 10 ? 'Good' : 'Low',
                    style: TextStyle(color: rateColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Sparkline trend
        if (_spots.length >= 2)
          Expanded(
            child: LineChart(
              LineChartData(
                minY: -20,
                maxY: 100,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(1)}%',
                          TextStyle(color: _getRateColor(spot.y, brightness), fontSize: 11, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
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
                      reservedSize: 30,
                      interval: 25,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()}%', style: const TextStyle(color: Colors.white54, fontSize: 8));
                      },
                    ),
                  ),
                  topTitles: PlutusChartStyle.hiddenAxisTitles(),
                  rightTitles: PlutusChartStyle.hiddenAxisTitles(),
                ),
                borderData: PlutusChartStyle.lineBorderData(brightness: Theme.of(context).brightness),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: 20,
                      color: AppColors.positive(brightness).withOpacity(0.3),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        style: TextStyle(color: AppColors.positive(brightness), fontSize: 8),
                        labelResolver: (_) => '20%',
                      ),
                    ),
                  ],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _spots,
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [AppColors.negative(brightness), Colors.orange, AppColors.positive(brightness)],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: _getRateColor(spot.y, brightness),
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
                          AppColors.positive(brightness).withOpacity(0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          const Expanded(
            child: Center(
              child: Text('Not enough data for trend', style: TextStyle(color: Colors.white54, fontSize: 11)),
            ),
          ),
      ],
    );
  }
}
