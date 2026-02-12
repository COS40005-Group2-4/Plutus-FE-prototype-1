import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'storage.dart';
import 'transaction_service.dart';
import 'models/transaction_model.dart';
import 'models/user_model.dart';
import 'widgets/glass_container.dart';
import 'widgets/export_dialog.dart';
import 'widgets/export_preview_dialog.dart';
import 'widgets/profile_widget.dart';
import 'widgets/roi_widget.dart';
import 'widgets/irr_widget.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'services/currency_service.dart';
import 'services/database_service.dart';
import 'services/export_service.dart';
import 'services/user_service.dart';
import 'utils/date_time_formatter.dart';
import 'l10n/app_localizations.dart';

const Color blue = Color(0xFF4285F4);
const Color red = Color(0xFFEA4335);
const Color yellow = Color(0xFFFBBC05);
const Color green = Color(0xFF34A853);

class DataWidget extends StatelessWidget {
  DataWidget({super.key, required this.item});

  final ColoredDashboardItem item;

  final Map<String, Widget Function(ColoredDashboardItem i)> _map = {
    "profile": (l) => const ProfileDashboardWidget(),
    "budget": (l) => const BudgetTrackingWidget(),
    "history": (l) => const TransactionHistoryWidget(),
    "import": (l) => const ReportImportWidget(),
    "export": (l) => const ReportExportWidget(),
    "roi": (l) => const RoiWidget(),
    "irr": (l) => const IrrWidget(),
  };

  @override
  Widget build(BuildContext context) {
    final dataKey = item.data;
    final builder = dataKey != null ? _map[dataKey] : null;
    if (builder == null) {
      return const SizedBox.shrink();
    }
    return builder(item);
  }
}

// Budget Tracking Display Widget
class BudgetTrackingWidget extends StatefulWidget {
  const BudgetTrackingWidget({super.key});

  @override
  State<BudgetTrackingWidget> createState() => _BudgetTrackingWidgetState();
}

class _BudgetTrackingWidgetState extends State<BudgetTrackingWidget> {
  late TransactionService _transactionService;
  bool _isYearlyView = false;
  DateTime _selectedDate = DateTime.now();
  double _monthlyBudget = 0;
  double _yearlyBudget = 0;
  AppCurrency _budgetCurrency = AppCurrency.usd;
  bool _isEditMode = false;
  final TextEditingController _budgetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _transactionService = TransactionService();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUserId != null) {
      _transactionService.setCurrentUser(authProvider.currentUserId!);
    }
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _budgetCurrency = settings.currency;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _transactionService.notifyTransactionUpdate();
    });
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  double get _currentBudget => _isYearlyView ? _yearlyBudget : _monthlyBudget;

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return GlassContainer(
          color: blue,
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

                    return _BudgetContent(
                      key: ValueKey('budget_${settings.currency.code}_${_selectedDate}_${_isYearlyView}_${_budgetCurrency.code}'),
                      transactions: transactions,
                      settings: settings,
                      targetBudget: _currentBudget,
                      budgetCurrency: _budgetCurrency,
                      isYearlyView: _isYearlyView,
                      selectedDate: _selectedDate,
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
              AppLocalizations.of(context).widgetBudgetOverview,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _isYearlyView = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: !_isYearlyView ? Colors.white.withOpacity(0.3) : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Month',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: !_isYearlyView ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => setState(() => _isYearlyView = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isYearlyView ? Colors.white.withOpacity(0.3) : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Year',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: _isYearlyView ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (_isEditMode)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () {
                      setState(() {
                        _isEditMode = false;
                        _budgetController.clear();
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                    onPressed: () {
                      setState(() {
                        _isEditMode = true;
                        _budgetController.text = _currentBudget > 0 ? _currentBudget.toString() : '';
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
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
                  if (_isYearlyView) {
                    _selectedDate = DateTime(_selectedDate.year - 1);
                  } else {
                    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
                  }
                });
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            Text(
              _isYearlyView
                  ? '${_selectedDate.year}'
                  : '${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
              onPressed: () {
                setState(() {
                  if (_isYearlyView) {
                    _selectedDate = DateTime(_selectedDate.year + 1);
                  } else {
                    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
                  }
                });
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        if (_isEditMode)
          GlassContainer(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            opacity: 0.1,
            borderRadius: 6,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Target Budget (${_isYearlyView ? 'Year' : 'Month'}):',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _budgetController,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white30),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green, size: 20),
                      onPressed: () {
                        setState(() {
                          final value = double.tryParse(_budgetController.text) ?? 0;
                          if (_isYearlyView) {
                            _yearlyBudget = value;
                          } else {
                            _monthlyBudget = value;
                          }
                          _isEditMode = false;
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Currency:',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white30),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButton<AppCurrency>(
                        value: _budgetCurrency,
                        dropdownColor: Colors.black87,
                        underline: const SizedBox(),
                        isDense: true,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        items: AppCurrency.values.map((currency) {
                          return DropdownMenuItem(
                            value: currency,
                            child: Text('${currency.symbol} ${currency.code}'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _budgetCurrency = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
      if (_isYearlyView) {
        return tx.dateTime.year == _selectedDate.year;
      } else {
        return tx.dateTime.year == _selectedDate.year && tx.dateTime.month == _selectedDate.month;
      }
    }).toList();
  }
}

class _BudgetContent extends StatefulWidget {
  final List<Transaction> transactions;
  final SettingsProvider settings;
  final double targetBudget;
  final AppCurrency budgetCurrency;
  final bool isYearlyView;
  final DateTime selectedDate;

  const _BudgetContent({
    super.key,
    required this.transactions,
    required this.settings,
    required this.targetBudget,
    required this.budgetCurrency,
    required this.isYearlyView,
    required this.selectedDate,
  });

  @override
  State<_BudgetContent> createState() => _BudgetContentState();
}

class _BudgetContentState extends State<_BudgetContent> {
  final CurrencyService _currencyService = CurrencyService();
  double _totalIncome = 0;
  double _totalExpense = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _calculateTotals();
  }

  @override
  void didUpdateWidget(_BudgetContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings.currency != widget.settings.currency ||
        oldWidget.budgetCurrency != widget.budgetCurrency ||
        oldWidget.transactions != widget.transactions) {
      _calculateTotals();
    }
  }

  Future<void> _calculateTotals() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    double income = 0;
    double expense = 0;

    for (var transaction in widget.transactions) {
      double amount = transaction.totalAmount;

      final sourceCurrency = transaction.currency.toUpperCase();
      final targetCurrency = widget.budgetCurrency.code.toUpperCase();
      
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
        expense += amount;
      } else {
        income += amount;
      }
    }

    if (mounted) {
      setState(() {
        _totalIncome = income;
        _totalExpense = expense;
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

    final balance = _totalIncome - _totalExpense;
    final budgetUsage = widget.targetBudget > 0 ? (_totalExpense / widget.targetBudget).clamp(0.0, 1.5) : 0.0;
    
    // Calculate prediction
    final now = DateTime.now();
    final isCurrentPeriod = widget.isYearlyView 
        ? now.year == widget.selectedDate.year
        : (now.year == widget.selectedDate.year && now.month == widget.selectedDate.month);
    
    double predictedExpense = _totalExpense;
    if (isCurrentPeriod && _totalExpense > 0) {
      if (widget.isYearlyView) {
        final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
        final daysInYear = DateTime(now.year, 12, 31).difference(DateTime(now.year, 1, 1)).inDays + 1;
        final dailyAverage = _totalExpense / dayOfYear;
        predictedExpense = dailyAverage * daysInYear;
      } else {
        final dayOfMonth = now.day;
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        final dailyAverage = _totalExpense / dayOfMonth;
        predictedExpense = dailyAverage * daysInMonth;
      }
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.targetBudget > 0) ...[
            _buildGaugeChart(budgetUsage, predictedExpense),
            const SizedBox(height: 16),
          ],
          _buildSummary(balance, predictedExpense, isCurrentPeriod),
        ],
      ),
    );
  }

  Widget _buildGaugeChart(double usage, double predictedExpense) {
    final predictedUsage = widget.targetBudget > 0 
        ? (predictedExpense / widget.targetBudget).clamp(0.0, 1.5) 
        : 0.0;

    return Column(
      children: [
        SizedBox(
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              SizedBox(
                height: 140,
                width: 140,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 14,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.1)),
                ),
              ),
              // Predicted usage (lighter color)
              if (predictedUsage > usage)
                SizedBox(
                  height: 140,
                  width: 140,
                  child: CircularProgressIndicator(
                    value: predictedUsage.clamp(0.0, 1.0),
                    strokeWidth: 14,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      (predictedUsage < 0.7 ? Colors.green : (predictedUsage < 0.9 ? Colors.orange : Colors.red))
                          .withOpacity(0.3),
                    ),
                  ),
                ),
              // Current usage
              SizedBox(
                height: 140,
                width: 140,
                child: CircularProgressIndicator(
                  value: usage.clamp(0.0, 1.0),
                  strokeWidth: 14,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    usage < 0.7 ? Colors.green : (usage < 0.9 ? Colors.orange : Colors.red),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(usage * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'of budget',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (predictedUsage > usage) ...[
          const SizedBox(height: 8),
          Text(
            'Predicted: ${(predictedUsage * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummary(double balance, double predictedExpense, bool isCurrentPeriod) {
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      opacity: 0.1,
      borderRadius: 8,
      child: Column(
        children: [
          if (widget.targetBudget > 0)
            _buildSummaryRow(
              'Budget',
              widget.targetBudget,
              Colors.blue,
            ),
          _buildSummaryRow(
            AppLocalizations.of(context).income,
            _totalIncome,
            Colors.green,
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            AppLocalizations.of(context).expense,
            _totalExpense,
            Colors.red,
          ),
          if (isCurrentPeriod && predictedExpense > _totalExpense) ...[
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Predicted',
              predictedExpense,
              Colors.orange,
            ),
          ],
          const Divider(color: Colors.white30),
          _buildSummaryRow(
            'Balance',
            balance,
            balance >= 0 ? Colors.green : Colors.red,
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
              currencyCode: widget.budgetCurrency.code,
              symbol: widget.budgetCurrency.symbol,
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
}

// Transaction History Display Widget
class TransactionHistoryWidget extends StatefulWidget {
  const TransactionHistoryWidget({super.key});

  @override
  State<TransactionHistoryWidget> createState() =>
      _TransactionHistoryWidgetState();
}

class _TransactionHistoryWidgetState extends State<TransactionHistoryWidget> {
  late TransactionService _transactionService;
  late DatabaseService _databaseService;
  bool _isEditMode = false;
  final Set<dynamic> _selectedTransactionIds = {};

  @override
  void initState() {
    super.initState();
    _transactionService = TransactionService();
    _databaseService = DatabaseService();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUserId != null) {
      _transactionService.setCurrentUser(authProvider.currentUserId!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _transactionService.notifyTransactionUpdate();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _deleteSelectedTransactions() async {
    if (_selectedTransactionIds.isEmpty) return;
    final count = _selectedTransactionIds.length;
    try {
      for (final txId in _selectedTransactionIds) {
        if (txId is int) {
          await _databaseService.deleteTransaction(txId);
        }
      }
      _selectedTransactionIds.clear();
      _isEditMode = false;
      _transactionService.notifyTransactionUpdate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted $count transaction${count > 1 ? 's' : ''}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete transaction: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return GlassContainer(
          color: green,
          opacity: 0.2,
          borderRadius: 16,
          padding: const EdgeInsets.all(12),
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
                    AppLocalizations.of(context).noTransactionHistory,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                );
              }

              final allTransactions = List<Transaction>.from(snapshot.data!);
              allTransactions.sort((a, b) => b.dateTime.compareTo(a.dateTime));
              final transactions = allTransactions.take(10).toList();

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context).widgetRecentTransactions,
                          style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                      if (_isEditMode)
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white, size: 20),
                              onPressed: () {
                                setState(() {
                                  _isEditMode = false;
                                  _selectedTransactionIds.clear();
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
                            if (_selectedTransactionIds.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: _deleteSelectedTransactions,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                          onPressed: () {
                            setState(() {
                              _isEditMode = true;
                              _selectedTransactionIds.clear();
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                    ),
                    const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        final txId = transaction.id ?? transaction.hashCode;
                        final isSelected = _selectedTransactionIds.contains(txId);

                        return GestureDetector(
                          onTap: _isEditMode
                              ? () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedTransactionIds.remove(txId);
                                    } else {
                                      _selectedTransactionIds.add(txId);
                                    }
                                  });
                                }
                              : null,
                          child: GlassContainer(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(8),
                            color: isSelected ? Colors.blue : Colors.white,
                            opacity: isSelected ? 0.3 : 0.1,
                            borderRadius: 6,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (_isEditMode)
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (value) {
                                      setState(() {
                                        if (value ?? false) {
                                          _selectedTransactionIds.add(txId);
                                        } else {
                                          _selectedTransactionIds.remove(txId);
                                        }
                                      });
                                    },
                                    fillColor: MaterialStateProperty.resolveWith<Color>(
                                      (states) => Colors.white,
                                    ),
                                  ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        transaction.label,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        DateTimeFormatter.formatDateTimeShort(
                                          transaction.dateTime,
                                          settings.dateFormat,
                                          settings.timeFormat,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                _DashboardTransactionAmount(
                                  key: ValueKey('dashboard_${transaction.dateTime}_${settings.currency.code}'),
                                  transaction: transaction,
                                  settings: settings,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      );
    },
    );
  }
}

class _DashboardTransactionAmount extends StatefulWidget {
  final Transaction transaction;
  final SettingsProvider settings;

  const _DashboardTransactionAmount({
    super.key,
    required this.transaction,
    required this.settings,
  });

  @override
  State<_DashboardTransactionAmount> createState() => _DashboardTransactionAmountState();
}

class _DashboardTransactionAmountState extends State<_DashboardTransactionAmount> {
  final CurrencyService _currencyService = CurrencyService();
  double? _convertedAmount;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _convertAmount();
  }

  @override
  void didUpdateWidget(_DashboardTransactionAmount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings.currency != widget.settings.currency ||
        oldWidget.transaction != widget.transaction) {
      _convertAmount();
    }
  }

  Future<void> _convertAmount() async {
    final sourceCurrency = widget.transaction.currency.toUpperCase();
    final targetCurrency = widget.settings.currency.code.toUpperCase();

    // No conversion needed if same currency
    if (sourceCurrency == targetCurrency) {
      if (mounted) {
        setState(() {
          _convertedAmount = widget.transaction.totalAmount;
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final converted = await _currencyService.convert(
        amount: widget.transaction.totalAmount,
        fromCurrency: sourceCurrency,
        toCurrency: targetCurrency,
      );

      if (mounted) {
        setState(() {
          _convertedAmount = converted;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _convertedAmount = widget.transaction.totalAmount;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(strokeWidth: 1, color: Colors.white),
      );
    }

    final displayAmount = _convertedAmount ?? widget.transaction.totalAmount;
    final formatted = _currencyService.formatCurrency(
      amount: displayAmount,
      currencyCode: widget.settings.currency.code,
      symbol: widget.settings.currency.symbol,
    );

    return Text(
      '${widget.transaction.isExpense ? '-' : '+'}$formatted',
      style: TextStyle(
        color: widget.transaction.isExpense ? Colors.red : Colors.green,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}

// Report Import Button Widget
class ReportImportWidget extends StatelessWidget {
  const ReportImportWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      color: yellow,
      opacity: 0.2,
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
          const Icon(Icons.upload_file, size: 40, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).widgetImportReport,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).clickImportTransactions,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, "/import");
            },
            icon: const Icon(Icons.add),
            label: Text(AppLocalizations.of(context).import),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: yellow,
            ),
          ),
        ],
        ),
      ),
    );
  }
}

// Report Export Button Widget
class ReportExportWidget extends StatefulWidget {
  const ReportExportWidget({super.key});

  @override
  State<ReportExportWidget> createState() => _ReportExportWidgetState();
}

class _ReportExportWidgetState extends State<ReportExportWidget> {
  final TransactionService _transactionService = TransactionService();
  final ExportService _exportService = ExportService();
  final UserService _userService = UserService();
  bool _isExporting = false;

  Future<void> _showExportDialog() async {
    final options = await showDialog<ExportOptions>(
      context: context,
      builder: (context) => const ExportDialog(),
    );

    if (options == null || !mounted) return;

    setState(() => _isExporting = true);

    try {
      // Show loading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text('Generating export...', overflow: TextOverflow.ellipsis)),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );

      // Get current user
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUserId != null
          ? await _userService.getUserById(authProvider.currentUserId!)
          : null;

      // Get transactions
      final transactions = await _transactionService.getTransactions();

      // Generate export
      final result = await _exportService.exportData(
        options: options,
        transactions: transactions,
        user: user,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show preview dialog
      await showDialog(
        context: context,
        builder: (context) => ExportPreviewDialog(
          filePath: result.filePath,
          format: result.format,
          pdfDocument: result.pdfDocument,
          txtContent: result.txtContent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      color: red,
      opacity: 0.2,
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
          const Icon(Icons.download, size: 40, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).widgetExportReport,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).clickExportTransactions,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isExporting ? null : _showExportDialog,
            icon: _isExporting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(red),
                    ),
                  )
                : const Icon(Icons.save_alt),
            label: Text(_isExporting ? AppLocalizations.of(context).exporting : AppLocalizations.of(context).export),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: red,
            ),
          ),
        ],
        ),
      ),
    );
  }
}

// Profile Display Widget for Dashboard
class ProfileDashboardWidget extends StatefulWidget {
  const ProfileDashboardWidget({super.key});

  @override
  State<ProfileDashboardWidget> createState() => _ProfileDashboardWidgetState();
}

class _ProfileDashboardWidgetState extends State<ProfileDashboardWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final currentUser = authProvider.currentUser;

        if (currentUser == null) {
          return GlassContainer(
            color: Colors.purple,
            opacity: 0.2,
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: const Center(
              child: Text(
                'No user logged in',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          );
        }

        return GlassContainer(
          color: Colors.purple,
          opacity: 0.2,
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: ProfileWidget(
            user: currentUser,
            defaultAvatarAsset: 'lib/assets/avatar/default-avatar.jpg',
            isCompact: true,
          ),
          ),
        );
      },
    );
  }
}
