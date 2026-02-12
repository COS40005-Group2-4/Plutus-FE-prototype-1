import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction_model.dart';
import '../transaction_service.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../services/currency_service.dart';
import '../l10n/app_localizations.dart';
import 'glass_container.dart';

class CashflowWidget extends StatefulWidget {
  const CashflowWidget({super.key});

  @override
  State<CashflowWidget> createState() => _CashflowWidgetState();
}

class _CashflowWidgetState extends State<CashflowWidget> {
  late TransactionService _transactionService;
  bool _isMonthlyView = true;
  DateTime _selectedDate = DateTime.now();
  bool _showBarChart = true;

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
          color: const Color(0xFF2A5470),
          opacity: 0.2,
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder<List<Transaction>>(
                  stream: _transactionService.transactionStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          AppLocalizations.of(context).noTransactionsFound,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      );
                    }

                    final transactions = _filterTransactions(snapshot.data!);

                    return _CashflowContent(
                      key: ValueKey('cashflow_${settings.currency.code}_${_selectedDate}_${_isMonthlyView}_${_showBarChart}'),
                      transactions: transactions,
                      settings: settings,
                      isMonthlyView: _isMonthlyView,
                      selectedDate: _selectedDate,
                      showBarChart: _showBarChart,
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

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Cash Flow',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _isMonthlyView = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isMonthlyView ? Colors.white.withOpacity(0.3) : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Month',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: _isMonthlyView ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => setState(() => _isMonthlyView = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: !_isMonthlyView ? Colors.white.withOpacity(0.3) : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Year',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: !_isMonthlyView ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _showBarChart ? Icons.bar_chart : Icons.show_chart,
                    color: Colors.white,
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
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
              onPressed: () {
                setState(() {
                  if (_isMonthlyView) {
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
              _isMonthlyView
                  ? '${_getMonthName(_selectedDate.month)} ${_selectedDate.year}'
                  : '${_selectedDate.year}',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
              onPressed: () {
                setState(() {
                  if (_isMonthlyView) {
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
      ],
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    return transactions.where((tx) {
      if (_isMonthlyView) {
        return tx.dateTime.year == _selectedDate.year && tx.dateTime.month == _selectedDate.month;
      } else {
        return tx.dateTime.year == _selectedDate.year;
      }
    }).toList();
  }
}


class _CashflowContent extends StatefulWidget {
  final List<Transaction> transactions;
  final SettingsProvider settings;
  final bool isMonthlyView;
  final DateTime selectedDate;
  final bool showBarChart;

  const _CashflowContent({
    super.key,
    required this.transactions,
    required this.settings,
    required this.isMonthlyView,
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
        oldWidget.isMonthlyView != widget.isMonthlyView) {
      _calculateCashflow();
    }
  }

  Future<void> _calculateCashflow() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    final incomeData = <int, double>{};
    final expenseData = <int, double>{};

    if (widget.isMonthlyView) {
      // Group by day of month
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
    } else {
      // Group by month of year
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final totalIncome = _incomeData.values.fold(0.0, (sum, val) => sum + val);
    final totalExpense = _expenseData.values.fold(0.0, (sum, val) => sum + val);
    final netCashflow = totalIncome - totalExpense;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSummary(totalIncome, totalExpense, netCashflow),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: widget.showBarChart ? _buildBarChart() : _buildLineChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(double income, double expense, double netCashflow) {
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      opacity: 0.1,
      borderRadius: 8,
      child: Column(
        children: [
          _buildSummaryRow(
            AppLocalizations.of(context).income,
            income,
            Colors.green,
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            AppLocalizations.of(context).expense,
            expense,
            Colors.red,
          ),
          const Divider(color: Colors.white30),
          _buildSummaryRow(
            'Net Cash Flow',
            netCashflow,
            netCashflow >= 0 ? Colors.green : Colors.red,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            '$label:',
            style: TextStyle(
              color: isBold ? Colors.white : Colors.white70,
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
              symbol: widget.settings.currency.symbol,
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
    final maxValue = [
      ..._incomeData.values,
      ..._expenseData.values,
    ].fold(0.0, (max, val) => val > max ? val : max);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final period = group.x.toInt() + 1;
              final value = rod.toY;
              final label = rodIndex == 0 ? 'Income' : 'Expense';
              return BarTooltipItem(
                '$label\n${widget.isMonthlyView ? 'Day' : 'Month'} $period\n${_currencyService.formatCurrency(
                  amount: value,
                  currencyCode: widget.settings.currency.code,
                  symbol: widget.settings.currency.symbol,
                )}',
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
                final index = value.toInt() + 1;
                if (widget.isMonthlyView) {
                  if (index % 5 == 1 || index == 1) {
                    return Text(
                      '$index',
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    );
                  }
                } else {
                  const months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                  return Text(
                    months[index - 1],
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
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
              color: Colors.white.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: _buildBarGroups(),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    final groups = <BarChartGroupData>[];
    final keys = widget.isMonthlyView
        ? List.generate(_incomeData.length, (i) => i + 1)
        : List.generate(12, (i) => i + 1);

    for (int i = 0; i < keys.length; i++) {
      final key = keys[i];
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: _incomeData[key] ?? 0,
              color: Colors.green.withOpacity(0.7),
              width: widget.isMonthlyView ? 4 : 8,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(2),
                topRight: Radius.circular(2),
              ),
            ),
            BarChartRodData(
              toY: _expenseData[key] ?? 0,
              color: Colors.red.withOpacity(0.7),
              width: widget.isMonthlyView ? 4 : 8,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(2),
                topRight: Radius.circular(2),
              ),
            ),
          ],
        ),
      );
    }

    return groups;
  }

  Widget _buildLineChart() {
    final maxValue = [
      ..._incomeData.values,
      ..._expenseData.values,
    ].fold(0.0, (max, val) => val > max ? val : max);

    return LineChart(
      LineChartData(
        maxY: maxValue * 1.2,
        minY: 0,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final period = spot.x.toInt() + 1;
                final label = spot.barIndex == 0 ? 'Income' : 'Expense';
                return LineTooltipItem(
                  '$label\n${widget.isMonthlyView ? 'Day' : 'Month'} $period\n${_currencyService.formatCurrency(
                    amount: spot.y,
                    currencyCode: widget.settings.currency.code,
                    symbol: widget.settings.currency.symbol,
                  )}',
                  TextStyle(
                    color: spot.barIndex == 0 ? Colors.green : Colors.red,
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
                final index = value.toInt() + 1;
                if (widget.isMonthlyView) {
                  if (index % 5 == 1 || index == 1) {
                    return Text(
                      '$index',
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    );
                  }
                } else {
                  const months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                  return Text(
                    months[index - 1],
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
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
              color: Colors.white.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: _buildLineSpots(_incomeData),
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.2),
            ),
          ),
          LineChartBarData(
            spots: _buildLineSpots(_expenseData),
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.red.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _buildLineSpots(Map<int, double> data) {
    final spots = <FlSpot>[];
    final keys = widget.isMonthlyView
        ? List.generate(data.length, (i) => i + 1)
        : List.generate(12, (i) => i + 1);

    for (int i = 0; i < keys.length; i++) {
      final key = keys[i];
      spots.add(FlSpot(i.toDouble(), data[key] ?? 0));
    }

    return spots;
  }
}
