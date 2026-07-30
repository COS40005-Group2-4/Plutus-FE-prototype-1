import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction_model.dart';
import '../providers/auth_notifier.dart';
import '../services/interfaces/interfaces.dart';
import '../di/service_locator.dart';
import '../providers/settings_notifier.dart';
import '../services/currency_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_spacing.dart';
import '../theme/plutus_tokens.dart';
import 'core/hero_card.dart';
import 'core/app_card.dart';
import 'chart_theme.dart';

class NetWorthTrendWidget extends ConsumerStatefulWidget {
  const NetWorthTrendWidget({super.key});

  @override
  ConsumerState<NetWorthTrendWidget> createState() => _NetWorthTrendWidgetState();
}

class _NetWorthTrendWidgetState extends ConsumerState<NetWorthTrendWidget> {
  late ITransactionService _transactionService;
  int _viewMode = 0; // 0 = Last 12 months, 1 = Yearly

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
    final PlutusTokens t = context.tokens;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Net Worth Trend',
                    style: TextStyle(color: t.text, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Tooltip(
                    message: AppLocalizations.of(context).widgetHelpNetWorthTrend,
                    child: Icon(
                      Icons.help_outline,
                      size: 14,
                      color: t.textMuted,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildToggle('Monthly', 0),
                  const SizedBox(width: AppSpacing.xs),
                  _buildToggle('Yearly', 1),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: StreamBuilder<List<Transaction>>(
              stream: _transactionService.transactionStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return Center(child: CircularProgressIndicator(color: t.text));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text('No transaction data', style: TextStyle(color: t.textSecondary, fontSize: 12)),
                  );
                }
                return _NetWorthContent(
                  key: ValueKey('networth_${settings.currency.code}_$_viewMode'),
                  transactions: snapshot.data!,
                  settings: settings,
                  viewMode: _viewMode,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(String label, int mode) {
    final PlutusTokens t = context.tokens;
    final bool selected = _viewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? t.surfaceSubtle : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? t.text : t.textMuted,
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _NetWorthContent extends StatefulWidget {
  final List<Transaction> transactions;
  final SettingsState settings;
  final int viewMode;

  const _NetWorthContent({
    super.key,
    required this.transactions,
    required this.settings,
    required this.viewMode,
  });

  @override
  State<_NetWorthContent> createState() => _NetWorthContentState();
}

class _NetWorthContentState extends State<_NetWorthContent> {
  final CurrencyService _currencyService = CurrencyService();
  List<FlSpot> _spots = [];
  List<String> _labels = [];
  double _currentNetWorth = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _calculateNetWorth();
  }

  @override
  void didUpdateWidget(_NetWorthContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transactions != widget.transactions ||
        oldWidget.settings.currency != widget.settings.currency ||
        oldWidget.viewMode != widget.viewMode) {
      _calculateNetWorth();
    }
  }

  Future<void> _calculateNetWorth() async {
    setState(() => _isLoading = true);

    final sorted = List<Transaction>.from(widget.transactions)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final Map<String, double> periodTotals = {};
    final targetCurrency = widget.settings.currency.code.toUpperCase();

    for (var tx in sorted) {
      String periodKey;
      if (widget.viewMode == 0) {
        periodKey = '${tx.dateTime.year}-${tx.dateTime.month.toString().padLeft(2, '0')}';
      } else {
        periodKey = '${tx.dateTime.year}';
      }

      double amount = tx.totalAmount;
      final sourceCurrency = tx.currency.toUpperCase();
      if (sourceCurrency != targetCurrency) {
        try {
          amount = await _currencyService.convert(
            amount: tx.totalAmount,
            fromCurrency: sourceCurrency,
            toCurrency: targetCurrency,
          );
        } catch (_) {}
      }

      final netAmount = tx.isExpense ? -amount : amount;
      periodTotals[periodKey] = (periodTotals[periodKey] ?? 0) + netAmount;
    }

    // Build cumulative net worth
    final sortedKeys = periodTotals.keys.toList()..sort();

    // For monthly view, show last 12 months
    List<String> displayKeys;
    if (widget.viewMode == 0 && sortedKeys.length > 12) {
      displayKeys = sortedKeys.sublist(sortedKeys.length - 12);
    } else {
      displayKeys = sortedKeys;
    }

    // Compute cumulative from all periods up to displayKeys start
    double cumulative = 0;
    for (var key in sortedKeys) {
      if (displayKeys.contains(key)) break;
      cumulative += periodTotals[key]!;
    }

    final spots = <FlSpot>[];
    final labels = <String>[];
    for (int i = 0; i < displayKeys.length; i++) {
      cumulative += periodTotals[displayKeys[i]]!;
      spots.add(FlSpot(i.toDouble(), cumulative));
      if (widget.viewMode == 0) {
        final parts = displayKeys[i].split('-');
        const months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
        labels.add(months[int.parse(parts[1]) - 1]);
      } else {
        labels.add(displayKeys[i].substring(2)); // Last 2 digits of year
      }
    }

    if (mounted) {
      setState(() {
        _spots = spots;
        _labels = labels;
        _currentNetWorth = cumulative;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final PlutusTokens t = context.tokens;
    final l10n = AppLocalizations.of(context);
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: t.text));
    }

    if (_spots.length < 2) {
      return Center(
        child: Text('Not enough data for trend', style: TextStyle(color: t.textSecondary, fontSize: 12)),
      );
    }

    final lineColor = t.chartCategorical.first;
    final maxY = _spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final minY = _spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final range = maxY - minY;

    return Column(
      children: [
        HeroCard(
          label: l10n.netWorth,
          value: '${widget.settings.currency.symbol}${PlutusChartStyle.formatCompactCurrency(_currentNetWorth)}',
        ),
        const SizedBox(height: AppSpacing.componentMd),
        Expanded(
          child: AppCard(
            child: RepaintBoundary(
              child: LineChart(
                LineChartData(
                  minY: minY - range * 0.1,
                  maxY: maxY + range * 0.1,
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) {
                        return spots.map((spot) {
                          return LineTooltipItem(
                            PlutusChartStyle.formatCompactCurrency(spot.y),
                            TextStyle(color: lineColor, fontSize: 11, fontWeight: FontWeight.bold),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  gridData: PlutusChartStyle.defaultGridData(maxValue: range > 0 ? range : 1, brightness: Theme.of(context).brightness),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= _labels.length) return const SizedBox.shrink();
                          // Show every other label if too many
                          if (_labels.length > 8 && idx % 2 != 0) return const SizedBox.shrink();
                          return Text(
                            _labels[idx],
                            style: TextStyle(color: t.textMuted, fontSize: 9),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            PlutusChartStyle.formatCompactCurrency(value),
                            style: TextStyle(color: t.textMuted, fontSize: 8),
                          );
                        },
                      ),
                    ),
                    topTitles: PlutusChartStyle.hiddenAxisTitles(),
                    rightTitles: PlutusChartStyle.hiddenAxisTitles(),
                  ),
                  borderData: PlutusChartStyle.lineBorderData(brightness: Theme.of(context).brightness),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _spots,
                      isCurved: true,
                      color: lineColor,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: _spots.length <= 12,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 3,
                            color: lineColor,
                            strokeWidth: 1,
                            strokeColor: t.text,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            lineColor.withValues(alpha:0.3),
                            lineColor.withValues(alpha:0.02),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
