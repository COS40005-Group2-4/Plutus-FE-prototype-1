import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction_model.dart';
import '../transaction_service.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../services/currency_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';
import 'glass_container.dart';

class CashflowWidget extends StatefulWidget {
  const CashflowWidget({super.key});

  @override
  State<CashflowWidget> createState() => _CashflowWidgetState();
}

class _CashflowWidgetState extends State<CashflowWidget> {
  late TransactionService _transactionService;
  int _viewMode = 0; // 0 = Monthly, 1 = Yearly, 2 = All Years
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
          color: AppColors.borderDark,
          opacity: 0.2,
          borderRadius: AppRadius.lg,
          padding: const EdgeInsets.all(AppSpacing.lg),
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
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context).cashflow,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _viewMode = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _viewMode == 0 ? Colors.white.withValues(alpha:0.3) : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Month',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: _viewMode == 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => setState(() => _viewMode = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _viewMode == 1 ? Colors.white.withValues(alpha:0.3) : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Year',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: _viewMode == 1 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => setState(() => _viewMode = 2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _viewMode == 2 ? Colors.white.withValues(alpha:0.3) : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'All',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: _viewMode == 2 ? FontWeight.bold : FontWeight.normal,
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
        if (_viewMode != 2) // Hide navigation for "All Years" view
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
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
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
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
          const Text(
            'All Years',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
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
  final SettingsProvider settings;
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
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
              const SizedBox(height: 16),
              SizedBox(
                height: chartHeight,
                child: widget.showBarChart ? _buildBarChart() : _buildLineChart(),
              ),
              const SizedBox(height: 8),
              _buildLegend(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegend() {
    final brightness = Theme.of(context).brightness;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(AppColors.positive(brightness), AppLocalizations.of(context).income),
        const SizedBox(width: 24),
        _buildLegendItem(AppColors.negative(brightness), AppLocalizations.of(context).expense),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
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
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
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
            AppColors.positive(Theme.of(context).brightness),
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            AppLocalizations.of(context).expense,
            expense,
            AppColors.negative(Theme.of(context).brightness),
          ),
          const Divider(color: Colors.white30),
          _buildSummaryRow(
            AppLocalizations.of(context).netCashflow,
            netCashflow,
            netCashflow >= 0 ? AppColors.positive(Theme.of(context).brightness) : AppColors.negative(Theme.of(context).brightness),
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
                final keys = _incomeData.keys.toList()..sort();
                if (value.toInt() >= keys.length) return const SizedBox.shrink();
                
                final period = keys[value.toInt()];
                if (widget.viewMode == 0) {
                  // Monthly - show day numbers
                  if (period % 5 == 1 || period == 1) {
                    return Text(
                      '$period',
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    );
                  }
                } else if (widget.viewMode == 1) {
                  // Yearly - show month initials
                  const months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                  return Text(
                    months[period - 1],
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  );
                } else {
                  // All years - show year numbers
                  return Text(
                    '$period',
                    style: const TextStyle(color: Colors.white70, fontSize: 9),
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
                  style: const TextStyle(color: Colors.white70, fontSize: 8),
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
              color: Colors.white.withValues(alpha:0.1),
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
    final brightness = Theme.of(context).brightness;
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
              color: AppColors.positive(brightness).withValues(alpha:0.7),
              width: widget.viewMode == 0 ? 8 : 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: _expenseData[key] ?? 0,
              color: AppColors.negative(brightness).withValues(alpha:0.7),
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
                    color: spot.barIndex == 0 ? AppColors.positive(Theme.of(context).brightness) : AppColors.negative(Theme.of(context).brightness),
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
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    );
                  }
                } else if (widget.viewMode == 1) {
                  // Yearly - show month initials
                  const months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                  return Text(
                    months[period - 1],
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  );
                } else {
                  // All years - show year numbers
                  return Text(
                    '$period',
                    style: const TextStyle(color: Colors.white70, fontSize: 9),
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
                  style: const TextStyle(color: Colors.white70, fontSize: 8),
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
              color: Colors.white.withValues(alpha:0.1),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha:0.2), width: 1),
            left: BorderSide(color: Colors.white.withValues(alpha:0.2), width: 1),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: _buildLineSpots(_incomeData),
            isCurved: false,
            color: AppColors.positive(Theme.of(context).brightness),
            barWidth: 2,
            isStrokeCapRound: false,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.positive(Theme.of(context).brightness).withValues(alpha:0.3),
                  AppColors.positive(Theme.of(context).brightness).withValues(alpha:0.05),
                ],
              ),
            ),
          ),
          LineChartBarData(
            spots: _buildLineSpots(_expenseData),
            isCurved: false,
            color: AppColors.negative(Theme.of(context).brightness),
            barWidth: 2,
            isStrokeCapRound: false,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.negative(Theme.of(context).brightness).withValues(alpha:0.3),
                  AppColors.negative(Theme.of(context).brightness).withValues(alpha:0.05),
                ],
              ),
            ),
          ),
        ],
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

