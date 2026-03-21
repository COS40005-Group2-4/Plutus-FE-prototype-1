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

// Category Budget Widget - Budget focused on each category
class CategoryBudgetWidget extends StatefulWidget {
  const CategoryBudgetWidget({super.key});

  @override
  State<CategoryBudgetWidget> createState() => _CategoryBudgetWidgetState();
}

class _CategoryBudgetWidgetState extends State<CategoryBudgetWidget> {
  late TransactionService _transactionService;
  late BudgetService _budgetService;
  DateTime _selectedDate = DateTime.now();
  bool _isYearlyView = false;
  bool _isEditMode = false;
  bool _showAddCategory = false;
  AppCurrency _budgetCurrency = AppCurrency.usd;

  // Category budgets: category name -> budget amount
  Map<String, double> _categoryBudgets = {};
  // Selected categories to display (user can add custom or select from existing)
  List<String> _selectedCategories = [];

  // Default expense categories based on transaction accounts
  static const List<String> _defaultCategories = [
    'Food',
    'Transportation',
    'Entertainment',
    'Shopping',
    'Bills',
    'Healthcare',
    'Education',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _transactionService = TransactionService();
    _budgetService = BudgetService();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUserId != null) {
      _transactionService.setCurrentUser(authProvider.currentUserId!);
      _loadCategoryBudgetPreferences(authProvider.currentUserId!);
    }
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _budgetCurrency = settings.currency;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _transactionService.notifyTransactionUpdate();
    });
  }

  Future<void> _loadCategoryBudgetPreferences(int userId) async {
    final prefs = await _budgetService.loadCategoryBudgetPreferences(userId);
    if (prefs != null && mounted) {
      setState(() {
        _categoryBudgets = Map.from(prefs.categoryBudgets);
        _selectedCategories = List.from(prefs.selectedCategories);
        _budgetCurrency = AppCurrency.fromCode(prefs.currencyCode);
      });
    } else {
      // Set default selected categories
      setState(() {
        _selectedCategories = _defaultCategories.take(4).toList();
      });
    }
  }

  Future<void> _saveCategoryBudgetPreferences() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUserId != null) {
      await _budgetService.saveCategoryBudgetPreferences(
        authProvider.currentUserId!,
        CategoryBudgetPreferences(
          categoryBudgets: Map.from(_categoryBudgets),
          selectedCategories: List.from(_selectedCategories),
          currencyCode: _budgetCurrency.code,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return GlassContainer(
          color: Colors.teal,
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
                    final categoryData = _calculateCategoryExpenses(transactions);

                    return _CategoryBudgetContent(
                      key: ValueKey('catbudget_${settings.currency.code}_${_selectedDate}_${_isYearlyView}'),
                      categoryData: categoryData,
                      categoryBudgets: _categoryBudgets,
                      selectedCategories: _selectedCategories,
                      settings: settings,
                      budgetCurrency: _budgetCurrency,
                      isYearlyView: _isYearlyView,
                      selectedDate: _selectedDate,
                      onCategoryBudgetChanged: (category, amount) {
                        setState(() {
                          _categoryBudgets[category] = amount;
                          _saveCategoryBudgetPreferences();
                        });
                      },
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
            Expanded(
              child: Text(
                'Category Budget',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
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
                IconButton(
                  icon: Icon(_showAddCategory ? Icons.close : Icons.add, color: Colors.white, size: 20),
                  onPressed: () {
                    setState(() {
                      _showAddCategory = !_showAddCategory;
                      _isEditMode = false;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                IconButton(
                  icon: Icon(_isEditMode ? Icons.close : Icons.edit, color: Colors.white, size: 20),
                  onPressed: () {
                    setState(() {
                      _isEditMode = !_isEditMode;
                      _showAddCategory = false;
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
        if (_isEditMode || _showAddCategory)
          _buildEditPanel(),
      ],
    );
  }

  Widget _buildEditPanel() {
    return GlassContainer(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      opacity: 0.1,
      borderRadius: 6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isEditMode) ...[
            const Text(
              'Set Budget per Category:',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            ..._selectedCategories.map((category) => _buildCategoryBudgetRow(category)),
          ],
          if (_showAddCategory) ...[
            const Text(
              'Select Categories to Track:',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _defaultCategories.map((category) {
                final isSelected = _selectedCategories.contains(category);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedCategories.remove(category);
                        _categoryBudgets.remove(category);
                      } else {
                        _selectedCategories.add(category);
                      }
                      _saveCategoryBudgetPreferences();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.teal : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Colors.teal : Colors.white30,
                      ),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Currency:',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                          _saveCategoryBudgetPreferences();
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  final Map<String, TextEditingController> _budgetControllers = {};

  Widget _buildCategoryBudgetRow(String category) {
    _budgetControllers[category] ??= TextEditingController(
      text: (_categoryBudgets[category] ?? 0) > 0 ? (_categoryBudgets[category]!).toStringAsFixed(0) : '',
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              category,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _budgetControllers[category],
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                border: const OutlineInputBorder(),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
                hintText: 'Budget for $category',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
              ),
              keyboardType: TextInputType.number,
              onSubmitted: (value) {
                final amount = double.tryParse(value) ?? 0;
                setState(() {
                  _categoryBudgets[category] = amount;
                  _saveCategoryBudgetPreferences();
                });
              },
            ),
          ),
        ],
      ),
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

  Map<String, double> _calculateCategoryExpenses(List<Transaction> transactions) {
    final Map<String, double> categoryTotals = {};

    for (final tx in transactions) {
      if (!tx.isExpense) continue;

      // Extract category from postings
      String category = 'Other';
      for (final posting in tx.postings) {
        final account = posting.account.toLowerCase();
        if (account.startsWith('expenses:')) {
          // Extract category name from "Expenses:Food" -> "Food"
          final parts = posting.account.split(':');
          if (parts.length > 1) {
            category = parts[1];
          }
          break;
        }
      }

      // Try to match with selected categories
      String matchedCategory = 'Other';
      for (final selectedCat in _selectedCategories) {
        if (category.toLowerCase() == selectedCat.toLowerCase()) {
          matchedCategory = selectedCat;
          break;
        }
      }

      // Check for partial matches
      if (matchedCategory == 'Other') {
        final lowerCategory = category.toLowerCase();
        for (final selectedCat in _selectedCategories) {
          if (lowerCategory.contains(selectedCat.toLowerCase()) ||
              selectedCat.toLowerCase().contains(lowerCategory)) {
            matchedCategory = selectedCat;
            break;
          }
        }
      }

      categoryTotals[matchedCategory] = (categoryTotals[matchedCategory] ?? 0) + tx.totalAmount;
    }

    return categoryTotals;
  }
}

class _CategoryBudgetContent extends StatefulWidget {
  final Map<String, double> categoryData;
  final Map<String, double> categoryBudgets;
  final List<String> selectedCategories;
  final SettingsProvider settings;
  final AppCurrency budgetCurrency;
  final bool isYearlyView;
  final DateTime selectedDate;
  final Function(String category, double amount)? onCategoryBudgetChanged;

  const _CategoryBudgetContent({
    super.key,
    required this.categoryData,
    required this.categoryBudgets,
    required this.selectedCategories,
    required this.settings,
    required this.budgetCurrency,
    required this.isYearlyView,
    required this.selectedDate,
    this.onCategoryBudgetChanged,
  });

  @override
  State<_CategoryBudgetContent> createState() => _CategoryBudgetContentState();
}

class _CategoryBudgetContentState extends State<_CategoryBudgetContent> {
  final CurrencyService _currencyService = CurrencyService();
  bool _isLoading = true;
  Map<String, double> _convertedCategoryData = {};

  @override
  void initState() {
    super.initState();
    _convertCategoryData();
  }

  @override
  void didUpdateWidget(_CategoryBudgetContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryData != widget.categoryData ||
        oldWidget.budgetCurrency != widget.budgetCurrency ||
        oldWidget.settings.currency != widget.settings.currency) {
      _convertCategoryData();
    }
  }

  Future<void> _convertCategoryData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    final converted = <String, double>{};

    for (final entry in widget.categoryData.entries) {
      double amount = entry.value;
      final targetCurrency = widget.budgetCurrency.code.toUpperCase();

      try {
        amount = await _currencyService.convert(
          amount: entry.value,
          fromCurrency: widget.settings.currency.code,
          toCurrency: targetCurrency,
        );
      } catch (e) {
        // Keep original amount
      }

      converted[entry.key] = amount;
    }

    if (mounted) {
      setState(() {
        _convertedCategoryData = converted;
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

    final hasBudgets = widget.categoryBudgets.values.any((b) => b > 0);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasBudgets) _buildBudgetProgressList(),
          const SizedBox(height: 8),
          _buildCategorySpendingList(),
        ],
      ),
    );
  }

  Widget _buildBudgetProgressList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Budget Progress',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...widget.selectedCategories.where((cat) => (widget.categoryBudgets[cat] ?? 0) > 0).map((category) {
          final spent = _convertedCategoryData[category] ?? 0;
          final budget = widget.categoryBudgets[category] ?? 0;
          final progress = budget > 0 ? (spent / budget).clamp(0.0, 1.5) : 0.0;
          final isOverBudget = spent > budget;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      '${_currencyService.formatCurrency(amount: spent, currencyCode: widget.budgetCurrency.code)} / ${_currencyService.formatCurrency(amount: budget, currencyCode: widget.budgetCurrency.code)}',
                      style: TextStyle(
                        color: isOverBudget ? Colors.red : Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress < 0.7 ? Colors.green : (progress < 0.9 ? Colors.orange : Colors.red),
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildCategorySpendingList() {
    final sortedCategories = _convertedCategoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedCategories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No expenses recorded for selected categories',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Spending by Category',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...sortedCategories.map((entry) {
          final budget = widget.categoryBudgets[entry.key] ?? 0;
          final isOverBudget = budget > 0 && entry.value > budget;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    entry.key,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    _currencyService.formatCurrency(
                      amount: entry.value,
                      currencyCode: widget.budgetCurrency.code,
                    ),
                    style: TextStyle(
                      color: isOverBudget ? Colors.red : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
