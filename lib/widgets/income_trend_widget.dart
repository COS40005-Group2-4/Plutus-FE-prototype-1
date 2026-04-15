import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction_model.dart';
import '../providers/auth_notifier.dart';
import '../services/interfaces/interfaces.dart';
import '../di/service_locator.dart';
import '../providers/settings_notifier.dart';
import '../services/currency_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';
import 'glass_container.dart';
import 'chart_theme.dart';
import '../l10n/app_localizations.dart';

class IncomeTrendWidget extends ConsumerStatefulWidget {
  const IncomeTrendWidget({super.key});

  @override
  ConsumerState<IncomeTrendWidget> createState() => _IncomeTrendWidgetState();
}

class _IncomeTrendWidgetState extends ConsumerState<IncomeTrendWidget> {
  late ITransactionService _transactionService;

  @override
  void initState() {
    super.initState();
    _transactionService = sl<ITransactionService>();
    final currentUserId = ref.read(authNotifierProvider.notifier).currentUserId;
    if (currentUserId != null) {
      _transactionService.setCurrentUser(currentUserId);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _transactionService.notifyTransactionUpdate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);
    return GlassContainer(
          color: AppColors.historyAccent,
          opacity: 0.2,
          borderRadius: AppRadius.lg,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.trending_up, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Income Trend',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  Tooltip(
                    message: AppLocalizations.of(context).widgetHelpIncomeTrend,
                    child: Icon(
                      Icons.help_outline,
                      size: 14,
                      color: AppColors.textTertiary(Theme.of(context).brightness),
                    ),
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
  }
}

class _IncomeTrendContent extends StatefulWidget {
  final List<Transaction> transactions;
  final SettingsState settings;

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
  List<FlSpot> _incomeSpots = [];
  List<FlSpot> _expenseSpots = [];
  List<String> _displayKeys = [];
  double _avgIncome = 0;
  double _currentNetCashFlow = 0;
  double _incomeMoMChange = 0; // % change, e.g. 8.2 means +8.2%
  bool _isLoading = true;
  int _calcGeneration = 0;

  @override
  void initState() {
    super.initState();
    _calculateIncomeAndExpenses();
  }

  @override
  void didUpdateWidget(_IncomeTrendContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transactions != widget.transactions) {
      _calculateIncomeAndExpenses();
    }
  }

  Future<void> _calculateIncomeAndExpenses() async {
    final myGeneration = ++_calcGeneration;
    setState(() => _isLoading = true);

    final targetCurrency = widget.settings.currency.code.toUpperCase();
    final Map<String, double> monthlyIncome = {};
    final Map<String, double> monthlyExpense = {};

    for (var tx in widget.transactions) {
      final key =
          '${tx.dateTime.year}-${tx.dateTime.month.toString().padLeft(2, '0')}';
      double amount = tx.totalAmount;
      final source = tx.currency.toUpperCase();
      if (source != targetCurrency) {
        try {
          amount = await _currencyService.convert(
              amount: tx.totalAmount,
              fromCurrency: source,
              toCurrency: targetCurrency);
        } catch (_) {}
      }
      if (tx.isExpense) {
        monthlyExpense[key] = (monthlyExpense[key] ?? 0) + amount;
      } else {
        monthlyIncome[key] = (monthlyIncome[key] ?? 0) + amount;
      }
    }

    // Union of keys so both series cover the same months
    final allKeys = {...monthlyIncome.keys, ...monthlyExpense.keys}.toList()
      ..sort();
    final displayKeys =
        allKeys.length > 12 ? allKeys.sublist(allKeys.length - 12) : allKeys;

    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];

    for (int i = 0; i < displayKeys.length; i++) {
      incomeSpots
          .add(FlSpot(i.toDouble(), monthlyIncome[displayKeys[i]] ?? 0));
      expenseSpots
          .add(FlSpot(i.toDouble(), monthlyExpense[displayKeys[i]] ?? 0));
    }

    final avg = incomeSpots.isNotEmpty
        ? incomeSpots.map((s) => s.y).reduce((a, b) => a + b) /
            incomeSpots.length
        : 0.0;

    // Net cash flow = income − expenses for the most recent month
    final lastIncome =
        incomeSpots.isNotEmpty ? incomeSpots.last.y : 0.0;
    final lastExpense =
        expenseSpots.isNotEmpty ? expenseSpots.last.y : 0.0;
    final netCashFlow = lastIncome - lastExpense;

    // MoM income % change
    double momChange = 0;
    if (incomeSpots.length >= 2) {
      final prev = incomeSpots[incomeSpots.length - 2].y;
      if (prev > 0) {
        momChange = ((lastIncome - prev) / prev) * 100;
      }
    }

    if (mounted && myGeneration == _calcGeneration) {
      setState(() {
        _incomeSpots = incomeSpots;
        _expenseSpots = expenseSpots;
        _displayKeys = displayKeys;
        _avgIncome = avg;
        _currentNetCashFlow = netCashFlow;
        _incomeMoMChange = momChange;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }

    if (_incomeSpots.length < 2) {
      return const Center(
        child: Text('Not enough income data',
            style: TextStyle(color: Colors.white70, fontSize: 12)),
      );
    }

    final brightness = Theme.of(context).brightness;

    // Y-axis ceiling: max of income or expense, with 20% headroom
    final rawMax = [..._incomeSpots, ..._expenseSpots]
        .map((s) => s.y)
        .fold(0.0, (a, b) => a > b ? a : b);
    final maxY = rawMax > 0 ? rawMax * 1.2 : 1.0;

    // Header stats
    final net = _currentNetCashFlow;
    final netSign = net >= 0 ? '+' : '-';
    final netStr =
        '$netSign${widget.settings.currency.symbol}'
        '${PlutusChartStyle.formatCompactCurrency(net.abs())}';
    final netColor = net >= 0
        ? AppColors.positive(brightness)
        : AppColors.negative(brightness);

    final momAbs = _incomeMoMChange.abs();
    final momArrow = _incomeMoMChange >= 0 ? '↑' : '↓';
    final momStr = '$momArrow ${momAbs.toStringAsFixed(1)}% income';
    final momColor = _incomeMoMChange >= 0
        ? AppColors.positive(brightness)
        : AppColors.negative(brightness);

    return Column(
      children: [
        // Header stats row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Net this month',
                    style: TextStyle(color: Colors.white38, fontSize: 9)),
                Text(netStr,
                    style: TextStyle(
                        color: netColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('vs last month',
                    style: TextStyle(color: Colors.white38, fontSize: 9)),
                Text(momStr,
                    style: TextStyle(
                        color: momColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Stacked area chart
        Expanded(
          child: RepaintBoundary(
            child: LineChart(
            LineChartData(
              maxY: maxY,
              minY: 0,
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final isIncome = spot.barIndex == 0;
                      final label = isIncome ? 'Income' : 'Expenses';
                      final color = isIncome
                          ? AppColors.positive(brightness)
                          : AppColors.negative(brightness);
                      return LineTooltipItem(
                        '$label: ${_currencyService.formatCurrency(amount: spot.y, currencyCode: widget.settings.currency.code)}',
                        TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      );
                    }).toList();
                  },
                ),
              ),
              gridData: PlutusChartStyle.defaultGridData(
                  maxValue: maxY,
                  brightness: brightness),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= _displayKeys.length) {
                        return const SizedBox.shrink();
                      }
                      // Show first, last, and every 3rd label to avoid overlap
                      if (idx != 0 && idx != _displayKeys.length - 1 && idx % 3 != 0) {
                        return const SizedBox.shrink();
                      }
                      final prev = idx > 0 ? _displayKeys[idx - 1] : null;
                      return Text(
                        PlutusChartStyle.monthAxisLabel(_displayKeys[idx], prev),
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 9),
                      );
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
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 8),
                      );
                    },
                  ),
                ),
                topTitles: PlutusChartStyle.hiddenAxisTitles(),
                rightTitles: PlutusChartStyle.hiddenAxisTitles(),
              ),
              borderData: PlutusChartStyle.lineBorderData(brightness: brightness),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: _avgIncome,
                    color: Colors.white.withValues(alpha: 0.25),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 8),
                      labelResolver: (_) => 'avg income',
                    ),
                  ),
                ],
              ),
              lineBarsData: [
                // Income line (barIndex == 0)
                LineChartBarData(
                  spots: _incomeSpots,
                  isCurved: true,
                  color: AppColors.positive(brightness),
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 3,
                        color: AppColors.positive(brightness),
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
                        AppColors.positive(brightness).withValues(alpha: 0.2),
                        AppColors.positive(brightness).withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                ),
                // Expenses line (barIndex == 1)
                LineChartBarData(
                  spots: _expenseSpots,
                  isCurved: true,
                  color: AppColors.negative(brightness),
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.negative(brightness).withValues(alpha: 0.2),
                        AppColors.negative(brightness).withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
      ],
    );
  }
}
