import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../transaction_service.dart';
import '../models/transaction_model.dart';
import '../widgets/glass_container.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../services/currency_service.dart';
import '../services/budget_service.dart';
import '../l10n/app_localizations.dart';

const Color blue = Color(0xFF4285F4);
const Color red = Color(0xFFEA4335);
const Color yellow = Color(0xFFFBBC05);
const Color green = Color(0xFF34A853);

// Budget Tracking Display Widget
class BudgetTrackingWidget extends StatefulWidget {
  const BudgetTrackingWidget({super.key});

  @override
  State<BudgetTrackingWidget> createState() => _BudgetTrackingWidgetState();
}

class _BudgetTrackingWidgetState extends State<BudgetTrackingWidget> {
  late TransactionService _transactionService;
  late BudgetService _budgetService;
  bool _isYearlyView = false;
  DateTime _selectedDate = DateTime.now();
  Map<int, double> _monthlyBudgets = {}; // month (1-12) -> budget
  double _yearlyBudget = 0;
  AppCurrency _budgetCurrency = AppCurrency.usd;
  bool _isEditMode = false;
  bool _showMonthlyBudgetEditor = false;
  final TextEditingController _budgetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _transactionService = TransactionService();
    _budgetService = BudgetService();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUserId != null) {
      _transactionService.setCurrentUser(authProvider.currentUserId!);
      _loadBudgetPreferences(authProvider.currentUserId!);
    }
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _budgetCurrency = settings.currency;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _transactionService.notifyTransactionUpdate();
    });
  }

  Future<void> _loadBudgetPreferences(int userId) async {
    final prefs = await _budgetService.loadBudgetPreferences(userId);
    if (prefs != null && mounted) {
      setState(() {
        _monthlyBudgets = Map.from(prefs.monthlyBudgets);
        _yearlyBudget = prefs.yearlyBudget;
        _budgetCurrency = AppCurrency.fromCode(prefs.currencyCode);
      });
    }
  }

  Future<void> _saveBudgetPreferences() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUserId != null) {
      final prefs = BudgetPreferences(
        monthlyBudgets: Map.from(_monthlyBudgets),
        yearlyBudget: _yearlyBudget,
        currencyCode: _budgetCurrency.code,
      );
      await _budgetService.saveBudgetPreferences(
        authProvider.currentUserId!,
        prefs,
      );
    }
  }

  double get _currentBudget {
    if (_isYearlyView) {
      return _yearlyBudget;
    } else {
      return _monthlyBudgets[_selectedDate.month] ?? 0;
    }
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

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
                      AppLocalizations.of(context).month,
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
                      AppLocalizations.of(context).year,
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
                if (_isYearlyView) ...[
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Yearly Budget:',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
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
                            _yearlyBudget = double.tryParse(_budgetController.text) ?? 0;
                            _isEditMode = false;
                            _saveBudgetPreferences();
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Budget for ${_getMonthName(_selectedDate.month)}:',
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
                            _monthlyBudgets[_selectedDate.month] = value;
                            _isEditMode = false;
                            _showMonthlyBudgetEditor = false;
                            _saveBudgetPreferences();
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _showMonthlyBudgetEditor = !_showMonthlyBudgetEditor;
                          });
                        },
                        icon: Icon(
                          _showMonthlyBudgetEditor ? Icons.expand_less : Icons.expand_more,
                          color: Colors.white70,
                          size: 16,
                        ),
                        label: Text(
                          _showMonthlyBudgetEditor ? 'Hide All Months' : 'Set All Months',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  if (_showMonthlyBudgetEditor) ...[
                    const SizedBox(height: 8),
                    GlassContainer(
                      padding: const EdgeInsets.all(8),
                      color: Colors.white,
                      opacity: 0.05,
                      borderRadius: 4,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Apply to all months:',
                                  style: TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: TextField(
                                  style: const TextStyle(color: Colors.white, fontSize: 11),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                    border: OutlineInputBorder(),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white30),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onSubmitted: (value) {
                                    final budget = double.tryParse(value) ?? 0;
                                    if (budget > 0) {
                                      setState(() {
                                        for (int i = 1; i <= 12; i++) {
                                          _monthlyBudgets[i] = budget;
                                        }
                                        _saveBudgetPreferences();
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.done_all, color: Colors.blue, size: 16),
                                onPressed: () {
                                  // Apply current month's budget to all
                                  final currentBudget = _monthlyBudgets[_selectedDate.month] ?? 0;
                                  if (currentBudget > 0) {
                                    setState(() {
                                      for (int i = 1; i <= 12; i++) {
                                        _monthlyBudgets[i] = currentBudget;
                                      }
                                      _saveBudgetPreferences();
                                    });
                                  }
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Apply current to all',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Divider(color: Colors.white30, height: 1),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: List.generate(12, (index) {
                              final month = index + 1;
                              final budget = _monthlyBudgets[month] ?? 0;
                              return SizedBox(
                                width: 70,
                                child: Column(
                                  children: [
                                    Text(
                                      _getMonthName(month),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    SizedBox(
                                      height: 28,
                                      child: TextField(
                                        controller: TextEditingController(
                                          text: budget > 0 ? budget.toStringAsFixed(0) : '',
                                        ),
                                        style: const TextStyle(color: Colors.white, fontSize: 10),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                          border: OutlineInputBorder(),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(color: Colors.white30),
                                          ),
                                        ),
                                        keyboardType: TextInputType.number,
                                        onSubmitted: (value) {
                                          setState(() {
                                            _monthlyBudgets[month] = double.tryParse(value) ?? 0;
                                            _saveBudgetPreferences();
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
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
                            child: Text(currency.isOriginal
                                ? currency.displayName
                                : '${currency.symbol} ${currency.code}'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _budgetCurrency = value;
                              _saveBudgetPreferences();
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final gaugeSize = (constraints.maxWidth * 0.6).clamp(80.0, 140.0);
        final strokeWidth = (gaugeSize * 0.1).clamp(8.0, 14.0);
        final amountFontSize = (gaugeSize * 0.12).clamp(12.0, 18.0);
        final subFontSize = (gaugeSize * 0.07).clamp(8.0, 10.0);
        final percentFontSize = (gaugeSize * 0.11).clamp(11.0, 16.0);

        return Column(
          children: [
            SizedBox(
              height: gaugeSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: gaugeSize,
                    width: gaugeSize,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: strokeWidth,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.1)),
                    ),
                  ),
                  if (predictedUsage > usage)
                    SizedBox(
                      height: gaugeSize,
                      width: gaugeSize,
                      child: CircularProgressIndicator(
                        value: predictedUsage.clamp(0.0, 1.0),
                        strokeWidth: strokeWidth,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          (predictedUsage < 0.7 ? Colors.green : (predictedUsage < 0.9 ? Colors.orange : Colors.red))
                              .withOpacity(0.3),
                        ),
                      ),
                    ),
                  SizedBox(
                    height: gaugeSize,
                    width: gaugeSize,
                    child: CircularProgressIndicator(
                      value: usage.clamp(0.0, 1.0),
                      strokeWidth: strokeWidth,
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
                        _currencyService.formatCurrency(
                          amount: _totalExpense,
                          currencyCode: widget.budgetCurrency.code,
                          ),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: amountFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'of ${_currencyService.formatCurrency(
                          amount: widget.targetBudget,
                          currencyCode: widget.budgetCurrency.code,
                          )}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: subFontSize,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(usage * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: usage < 0.7 ? Colors.green : (usage < 0.9 ? Colors.orange : Colors.red),
                          fontSize: percentFontSize,
                          fontWeight: FontWeight.bold,
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
      },
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