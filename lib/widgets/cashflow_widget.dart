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
import 'core/app_card.dart';

class CashflowWidget extends ConsumerStatefulWidget {
  const CashflowWidget({super.key});

  @override
  ConsumerState<CashflowWidget> createState() => _CashflowWidgetState();
}

class _CashflowWidgetState extends ConsumerState<CashflowWidget> {
  late ITransactionService _transactionService;
  int _viewMode = 0; // 0 = Monthly, 1 = Yearly, 2 = All Years
  DateTime _selectedDate = DateTime.now();
  bool _showBarChart = true;

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
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          _buildHeader(context),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: StreamBuilder<List<Transaction>>(
              stream: _transactionService.transactionStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: t.text),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      AppLocalizations.of(context).noTransactionsFound,
                      style: TextStyle(color: t.text, fontSize: 14),
                    ),
                  );
                }

                final transactions = _filterTransactions(snapshot.data!);

                return _CashflowContent(
                  key: ValueKey('cashflow_${settings.currency.code}_${_selectedDate}_${_viewMode}_$_showBarChart'),
                  transactions: transactions,
                  allTransactions: snapshot.data!,
                  settings: settings,
                  viewMode: _viewMode,
                  selectedDate: _selectedDate,
                  showBarChart: _showBarChart,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final PlutusTokens t = context.tokens;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  AppLocalizations.of(context).cashflow,
                  style: TextStyle(
                    color: t.text,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Tooltip(
                  message: AppLocalizations.of(context).widgetHelpCashflow,
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
                GestureDetector(
                  onTap: () => setState(() => _viewMode = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _viewMode == 0 ? t.surfaceSubtle : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Month',
                      style: TextStyle(
                        color: _viewMode == 0 ? t.text : t.textMuted,
                        fontSize: 12,
                        fontWeight: _viewMode == 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                GestureDetector(
                  onTap: () => setState(() => _viewMode = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _viewMode == 1 ? t.surfaceSubtle : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Year',
                      style: TextStyle(
                        color: _viewMode == 1 ? t.text : t.textMuted,
                        fontSize: 12,
                        fontWeight: _viewMode == 1 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                GestureDetector(
                  onTap: () => setState(() => _viewMode = 2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _viewMode == 2 ? t.surfaceSubtle : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'All',
                      style: TextStyle(
                        color: _viewMode == 2 ? t.text : t.textMuted,
                        fontSize: 12,
                        fontWeight: _viewMode == 2 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  icon: Icon(
                    _showBarChart ? Icons.bar_chart : Icons.show_chart,
                    color: t.text,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _showBarChart = !_showBarChart),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: _showBarChart ? 'Switch to Line Chart' : 'Switch to Bar Chart',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_viewMode != 2) // Hide navigation for "All Years" view
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: t.text, size: 20),
                onPressed: () {
                  setState(() {
                    if (_viewMode == 0) {
                      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
                    } else {
                      _selectedDate = DateTime(_selectedDate.year - 1);
                    }
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                _viewMode == 0
                    ? '${_getMonthName(_selectedDate.month)} ${_selectedDate.year}'
                    : '${_selectedDate.year}',
                style: TextStyle(color: t.text, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: t.text, size: 20),
                onPressed: () {
                  setState(() {
                    if (_viewMode == 0) {
                      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
                    } else {
                      _selectedDate = DateTime(_selectedDate.year + 1);
                    }
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        if (_viewMode == 2) // Show "All Years" label
          Text(
            'All Years',
            style: TextStyle(color: t.text, fontSize: 14, fontWeight: FontWeight.bold),
          ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    if (_viewMode == 2) {
      // All years - return all transactions
      return transactions;
    }
    
    return transactions.where((tx) {
      if (_viewMode == 0) {
        return tx.dateTime.year == _selectedDate.year && tx.dateTime.month == _selectedDate.month;
      } else {
        return tx.dateTime.year == _selectedDate.year;
      }
    }).toList();
  }
}


class _CashflowContent extends StatefulWidget {
  final List<Transaction> transactions;
  final List<Transaction> allTransactions;
  final SettingsState settings;
  final int viewMode;
  final DateTime selectedDate;
  final bool showBarChart;

  const _CashflowContent({
    super.key,
    required this.transactions,
    required this.allTransactions,
    required this.settings,
    required this.viewMode,
    required this.selectedDate,
    required this.showBarChart,
  });

  @override
  State<_CashflowContent> createState() => _CashflowContentState();
}

class _CashflowContentState extends State<_CashflowContent> {
  final CurrencyService _currencyService = CurrencyService();
  Map<int, double> _incomeData = {};
  Map<int, double> _expenseData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _calculateCashflow();
  }

  @override
  void didUpdateWidget(_CashflowContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings.currency != widget.settings.currency ||
        oldWidget.transactions != widget.transactions ||
        oldWidget.viewMode != widget.viewMode) {
      _calculateCashflow();
    }
  }

  Future<void> _calculateCashflow() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    final incomeData = <int, double>{};
    final expenseData = <int, double>{};

    if (widget.viewMode == 0) {
      // Monthly view - Group by day of month
      final daysInMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month + 1, 0).day;
      for (int i = 1; i <= daysInMonth; i++) {
        incomeData[i] = 0;
        expenseData[i] = 0;
      }

      for (var transaction in widget.transactions) {
        final day = transaction.dateTime.day;
        double amount = transaction.totalAmount;

        final sourceCurrency = transaction.currency.toUpperCase();
        final targetCurrency = widget.settings.currency.code.toUpperCase();

        if (sourceCurrency != targetCurrency) {
          try {
            amount = await _currencyService.convert(
              amount: transaction.totalAmount,
              fromCurrency: sourceCurrency,
              toCurrency: targetCurrency,
            );
          } catch (e) {
            amount = transaction.totalAmount;
          }
        }

        if (transaction.isExpense) {
          expenseData[day] = (expenseData[day] ?? 0) + amount;
        } else {
          incomeData[day] = (incomeData[day] ?? 0) + amount;
        }
      }
    } else if (widget.viewMode == 1) {
      // Yearly view - Group by month of year
      for (int i = 1; i <= 12; i++) {
        incomeData[i] = 0;
        expenseData[i] = 0;
      }

      for (var transaction in widget.transactions) {
        final month = transaction.dateTime.month;
        double amount = transaction.totalAmount;

        final sourceCurrency = transaction.currency.toUpperCase();
        final targetCurrency = widget.settings.currency.code.toUpperCase();

        if (sourceCurrency != targetCurrency) {
          try {
            amount = await _currencyService.convert(
              amount: transaction.totalAmount,
              fromCurrency: sourceCurrency,
              toCurrency: targetCurrency,
            );
          } catch (e) {
            amount = transaction.totalAmount;
          }
        }

        if (transaction.isExpense) {
          expenseData[month] = (expenseData[month] ?? 0) + amount;
        } else {
          incomeData[month] = (incomeData[month] ?? 0) + amount;
        }
      }
    } else {
      // All years view - Group by year
      // Find min and max years from all transactions
      if (widget.allTransactions.isNotEmpty) {
        final years = widget.allTransactions.map((tx) => tx.dateTime.year).toSet().toList()..sort();
        
        for (var year in years) {
          incomeData[year] = 0;
          expenseData[year] = 0;
        }

        for (var transaction in widget.allTransactions) {
          final year = transaction.dateTime.year;
          double amount = transaction.totalAmount;

          final sourceCurrency = transaction.currency.toUpperCase();
          final targetCurrency = widget.settings.currency.code.toUpperCase();

          if (sourceCurrency != targetCurrency) {
            try {
              amount = await _currencyService.convert(
                amount: transaction.totalAmount,
                fromCurrency: sourceCurrency,
                toCurrency: targetCurrency,
              );
            } catch (e) {
              amount = transaction.totalAmount;
            }
          }

          if (transaction.isExpense) {
            expenseData[year] = (expenseData[year] ?? 0) + amount;
          } else {
            incomeData[year] = (incomeData[year] ?? 0) + amount;
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _incomeData = incomeData;
        _expenseData = expenseData;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final PlutusTokens t = context.tokens;
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: t.text),
      );
    }

    final totalIncome = _incomeData.values.fold(0.0, (sum, val) => sum + val);
    final totalExpense = _expenseData.values.fold(0.0, (sum, val) => sum + val);
    final netCashflow = totalIncome - totalExpense;

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartHeight = (constraints.maxHeight * 0.4).clamp(120.0, 200.0);
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSummary(totalIncome, totalExpense, netCashflow),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: chartHeight,
                child: widget.showBarChart ? _buildBarChart() : _buildLineChart(),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildLegend(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegend() {
    final PlutusTokens t = context.tokens;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(t.chartCategorical.first, AppLocalizations.of(context).income),
        const SizedBox(width: 24),
        _buildLegendItem(t.chartCategorical[3], AppLocalizations.of(context).expense),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    final PlutusTokens t = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.7),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: TextStyle(
            color: t.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(double income, double expense, double netCashflow) {
    final PlutusTokens t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            AppLocalizations.of(context).income,
            income,
            t.success.text,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildSummaryRow(
            AppLocalizations.of(context).expense,
            expense,
            t.error.text,
          ),
          Divider(color: t.border),
          _buildSummaryRow(
            AppLocalizations.of(context).netCashflow,
            netCashflow,
            netCashflow >= 0 ? t.success.text : t.error.text,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, Color color, {bool isBold = false}) {
    final PlutusTokens t = context.tokens;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            '$label:',
            style: TextStyle(
              color: isBold ? t.text : t.textSecondary,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: Text(
            _currencyService.formatCurrency(
              amount: amount,
              currencyCode: widget.settings.currency.code,
            ),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: isBold ? 14 : 12,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart() {
    final PlutusTokens t = context.tokens;
    final maxValue = [
      ..._incomeData.values,
      ..._expenseData.values,
    ].fold(0.0, (max, val) => val > max ? val : max);

    return RepaintBoundary(
      child: BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue * 1.2,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final period = group.x.toInt() + 1;
              final value = rod.toY;
              final label = rodIndex == 0 ? 'Income' : 'Expense';
              String periodLabel;
              if (widget.viewMode == 0) {
                periodLabel = 'Day $period';
              } else if (widget.viewMode == 1) {
                periodLabel = 'Month $period';
              } else {
                periodLabel = 'Year $period';
              }
              return BarTooltipItem(
                '$label\n$periodLabel\n${_currencyService.formatCurrency(
                  amount: value,
                  currencyCode: widget.settings.currency.code,
                )}',
                TextStyle(color: t.text, fontSize: 10),
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
                final keys = _incomeData.keys.toList()..sort();
                if (value.toInt() >= keys.length) return const SizedBox.shrink();

                final period = keys[value.toInt()];
                if (widget.viewMode == 0) {
                  // Monthly - show day numbers
                  if (period % 5 == 1 || period == 1) {
                    return Text(
                      '$period',
                      style: TextStyle(color: t.textMuted, fontSize: 10),
                    );
                  }
                } else if (widget.viewMode == 1) {
                  // Yearly - show month initials
                  const months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                  return Text(
                    months[period - 1],
                    style: TextStyle(color: t.textMuted, fontSize: 10),
                  );
                } else {
                  // All years - show year numbers
                  return Text(
                    '$period',
                    style: TextStyle(color: t.textMuted, fontSize: 9),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  _currencyService.formatCurrency(
                    amount: value,
                    currencyCode: widget.settings.currency.code,
                    ),
                  style: TextStyle(color: t.textMuted, fontSize: 8),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxValue > 0 ? maxValue / 4 : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: t.border,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: _buildBarGroups(),
      ),
    ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    final PlutusTokens t = context.tokens;
    final groups = <BarChartGroupData>[];
    final keys = _incomeData.keys.toList()..sort();

    for (int i = 0; i < keys.length; i++) {
      final key = keys[i];
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: _incomeData[key] ?? 0,
              color: t.chartCategorical.first.withValues(alpha:0.7),
              width: widget.viewMode == 0 ? 8 : 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: _expenseData[key] ?? 0,
              color: t.chartCategorical[3].withValues(alpha:0.7),
              width: widget.viewMode == 0 ? 8 : 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return groups;
  }

  Widget _buildLineChart() {
    final PlutusTokens t = context.tokens;
    final maxValue = [
      ..._incomeData.values,
      ..._expenseData.values,
    ].fold(0.0, (max, val) => val > max ? val : max);

    return RepaintBoundary(
      child: LineChart(
      LineChartData(
        maxY: maxValue * 1.2,
        minY: 0,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final keys = _incomeData.keys.toList()..sort();
                final period = keys[spot.x.toInt()];
                final label = spot.barIndex == 0 ? 'Income' : 'Expense';
                String periodLabel;
                if (widget.viewMode == 0) {
                  periodLabel = 'Day $period';
                } else if (widget.viewMode == 1) {
                  periodLabel = 'Month $period';
                } else {
                  periodLabel = 'Year $period';
                }
                return LineTooltipItem(
                  '$label\n$periodLabel\n${_currencyService.formatCurrency(
                    amount: spot.y,
                    currencyCode: widget.settings.currency.code,
                    )}',
                  TextStyle(
                    color: spot.barIndex == 0 ? t.chartCategorical.first : t.chartCategorical[3],
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final keys = _incomeData.keys.toList()..sort();
                if (value.toInt() >= keys.length) return const SizedBox.shrink();

                final period = keys[value.toInt()];
                if (widget.viewMode == 0) {
                  // Monthly - show day numbers
                  if (period % 5 == 1 || period == 1) {
                    return Text(
                      '$period',
                      style: TextStyle(color: t.textMuted, fontSize: 10),
                    );
                  }
                } else if (widget.viewMode == 1) {
                  // Yearly - show month initials
                  const months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                  return Text(
                    months[period - 1],
                    style: TextStyle(color: t.textMuted, fontSize: 10),
                  );
                } else {
                  // All years - show year numbers
                  return Text(
                    '$period',
                    style: TextStyle(color: t.textMuted, fontSize: 9),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  _currencyService.formatCurrency(
                    amount: value,
                    currencyCode: widget.settings.currency.code,
                    ),
                  style: TextStyle(color: t.textMuted, fontSize: 8),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxValue > 0 ? maxValue / 4 : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: t.border,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: t.border, width: 1),
            left: BorderSide(color: t.border, width: 1),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: _buildLineSpots(_incomeData),
            isCurved: false,
            color: t.chartCategorical.first,
            barWidth: 2,
            isStrokeCapRound: false,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  t.chartCategorical.first.withValues(alpha:0.3),
                  t.chartCategorical.first.withValues(alpha:0.05),
                ],
              ),
            ),
          ),
          LineChartBarData(
            spots: _buildLineSpots(_expenseData),
            isCurved: false,
            color: t.chartCategorical[3],
            barWidth: 2,
            isStrokeCapRound: false,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  t.chartCategorical[3].withValues(alpha:0.3),
                  t.chartCategorical[3].withValues(alpha:0.05),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  List<FlSpot> _buildLineSpots(Map<int, double> data) {
    final spots = <FlSpot>[];
    final keys = _incomeData.keys.toList()..sort();

    for (int i = 0; i < keys.length; i++) {
      final key = keys[i];
      spots.add(FlSpot(i.toDouble(), data[key] ?? 0));
    }

    return spots;
  }
}

