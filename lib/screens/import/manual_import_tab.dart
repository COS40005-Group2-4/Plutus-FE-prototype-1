import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../transaction_service.dart';
import '../../widgets/glass_container.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';

class ManualImportTab extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final VoidCallback? onSuccess;

  const ManualImportTab({super.key, this.initialData, this.onSuccess});

  @override
  State<ManualImportTab> createState() => _ManualImportTabState();
}

class _ManualImportTabState extends State<ManualImportTab> {
  final _formKey = GlobalKey<FormState>();
  late TransactionService _service;

  late TextEditingController _payeeController;
  late TextEditingController _amountController;
  late TextEditingController _categoryController;
  late TextEditingController _descController;

  String _type = 'expense';
  String _currency = 'VND';
  DateTime _selectedDate = DateTime.now();
  bool _loading = false;

  // Child items (splits)
  List<Map<String, dynamic>> _items = [];

  // Category dropdown
  String? _selectedCategory;
  bool _isCustomCategory = false;
  final TextEditingController _customCategoryController = TextEditingController();

  // Common expense categories (aligned with Category Budget widget)
  static const List<String> _commonExpenseCategories = [
    'Food',
    'Transportation',
    'Entertainment',
    'Shopping',
    'Bills',
    'Healthcare',
    'Education',
    'Other',
  ];

  // Common income categories
  static const List<String> _commonIncomeCategories = [
    'Salary',
    'Freelance',
    'Investment',
    'Gift',
    'Other',
  ];

  List<String> get _currentCategories {
    return _type == 'expense' ? _commonExpenseCategories : _commonIncomeCategories;
  }

  @override
  void initState() {
    super.initState();
    _service = TransactionService();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUserId != null) {
      _service.setCurrentUser(authProvider.currentUserId!);
    }
    _initControllers();
  }

  void _initControllers() {
    final data = widget.initialData ?? {};
    _payeeController = TextEditingController(text: data['payee']?.toString() ?? '');
    _amountController = TextEditingController(text: data['amount']?.toString() ?? '');
    _categoryController = TextEditingController(text: data['category']?.toString() ?? '');
    _descController = TextEditingController(text: data['description']?.toString() ?? '');

    // Set selected category from data
    final categoryFromData = data['category']?.toString() ?? '';
    if (_currentCategories.contains(categoryFromData)) {
      _selectedCategory = categoryFromData;
      _isCustomCategory = false;
    } else if (categoryFromData.isNotEmpty) {
      _selectedCategory = 'Other';
      _isCustomCategory = true;
      _customCategoryController.text = categoryFromData;
    } else {
      _selectedCategory = null;
      _isCustomCategory = false;
    }

    if (data['type'] != null) {
      _type = data['type'].toString().toLowerCase();
    }

    // Set currency from data or default to VND
    final currencyFromData = data['currency']?.toString().toUpperCase() ?? 'VND';
    if (['VND', 'USD', 'EUR'].contains(currencyFromData)) {
      _currency = currencyFromData;
    } else {
      _currency = 'VND'; // Default if invalid currency
    }

    if (data['date'] != null) {
      try {
        _selectedDate = DateTime.parse(data['date']);
      } catch (e) {
        // ignore invalid date
      }
    }

    if (data['items'] != null && data['items'] is List) {
      _items = List<Map<String, dynamic>>.from(data['items']);
    } else {
      _items = [];
    }
  }

  @override
  void didUpdateWidget(ManualImportTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialData != oldWidget.initialData) {
      _initControllers();
    }
  }

  @override
  void dispose() {
    _payeeController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _descController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _addItem() {
    setState(() {
      _items.add({
        'description': '',
        'amount': 0.0,
      });
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      double amount = double.tryParse(_amountController.text) ?? 0.0;

      // Determine account name from category or use default
      String accountName = 'Cash'; // Default account
      String categoryPath = _categoryController.text.trim();

      // If category is empty, use default
      if (categoryPath.isEmpty) {
        categoryPath = _type == 'expense' ? 'Other' : 'General';
      }

      // Build account paths following P1:P2:P3 format
      String assetAccount = 'Assets:$accountName';
      String categoryAccount = _type == 'expense'
          ? 'Expenses:$categoryPath'
          : 'Income:$categoryPath';

      // Create postings for double-entry accounting
      List<Map<String, dynamic>> postings = [];

      if (_type == 'expense') {
        // For expense: deduct from asset, add to expense
        postings.add({
          'account': assetAccount,
          'amount': -amount.abs(),
          'commodity': _currency,
        });
        postings.add({
          'account': categoryAccount,
          'amount': amount.abs(),
          'commodity': _currency,
        });
      } else {
        // For income: add to asset, deduct from income source
        postings.add({
          'account': assetAccount,
          'amount': amount.abs(),
          'commodity': _currency,
        });
        postings.add({
          'account': categoryAccount,
          'amount': -amount.abs(),
          'commodity': _currency,
        });
      }

      // Add child items as additional postings if present
      if (_items.isNotEmpty) {
        double totalItemsAmount = 0.0;
        for (final item in _items) {
          final itemAmount = (item['amount'] as num?)?.toDouble() ?? 0.0;
          if (itemAmount > 0) {
            final itemDesc = item['description'] as String? ?? 'Item';
            String itemAccount = _type == 'expense'
                ? 'Expenses:$categoryPath:$itemDesc'
                : 'Income:$categoryPath:$itemDesc';

            // Add child item posting
            postings.add({
              'account': itemAccount,
              'amount': _type == 'expense' ? itemAmount.abs() : -itemAmount.abs(),
              'commodity': _currency,
            });
            totalItemsAmount += itemAmount;
          }
        }

        // Adjust the parent category posting to maintain balance
        if (totalItemsAmount > 0 && postings.length > 2) {
          // Remove the original category posting
          postings.removeAt(1);
        }
      }

      final transaction = {
        'date': _selectedDate.toIso8601String(),
        'payee': _payeeController.text,
        'description': _descController.text,
        'postings': postings,
        // Keep flat fields for backward compatibility
        'amount': _type == 'expense' ? -amount.abs() : amount.abs(),
        'currency': _currency,
        'type': _type,
        'category': categoryAccount,
        'account': assetAccount,
      };

      await _service.importTransaction(transaction);

      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).transactionSavedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );

        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else {
          // Auto-redirect to dashboard after successful manual entry
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.of(context).pop(true);
            }
          });
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).errorSaving}$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: 16,
        opacity: 0.1,
        child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Picker
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
              ),
            ),
            const SizedBox(height: 16),

            // Payee
            TextFormField(
              controller: _payeeController,
              decoration: const InputDecoration(
                labelText: 'Paid To',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Amount & Currency
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (double.tryParse(value) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _currency,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: 'VND', child: Text(AppLocalizations.of(context).vnd)),
                      DropdownMenuItem(value: 'USD', child: Text(AppLocalizations.of(context).usd)),
                      DropdownMenuItem(value: 'EUR', child: Text(AppLocalizations.of(context).eur)),
                    ],
                    onChanged: (val) => setState(() => _currency = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Type Dropdown
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'income', child: Text(AppLocalizations.of(context).income)),
                DropdownMenuItem(value: 'expense', child: Text(AppLocalizations.of(context).expense)),
              ],
              onChanged: (val) => setState(() => _type = val!),
            ),
            const SizedBox(height: 16),

            // Category
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: _isCustomCategory ? 'Other' : _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    ..._currentCategories.map((category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    )),
                  ],
                  onChanged: (val) {
                    if (val == 'Other') {
                      setState(() {
                        _isCustomCategory = true;
                        _selectedCategory = null;
                      });
                    } else {
                      setState(() {
                        _selectedCategory = val;
                        _isCustomCategory = false;
                        _categoryController.text = val ?? '';
                      });
                    }
                  },
                ),
                if (_isCustomCategory) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _customCategoryController,
                    decoration: const InputDecoration(
                      labelText: 'New Category',
                      border: OutlineInputBorder(),
                      hintText: 'Category name',
                    ),
                    onChanged: (val) {
                      _categoryController.text = val;
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Note',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Items Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).itemsSplits,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add_circle),
                  color: Colors.blue,
                ),
              ],
            ),
            if (_items.isNotEmpty) ...[
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            initialValue: item['description'],
                            decoration: const InputDecoration(
                              labelText: 'Item',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) => item['description'] = val,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: item['amount'].toString(),
                            decoration: const InputDecoration(
                              labelText: 'Amount',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (val) {
                               item['amount'] = double.tryParse(val) ?? 0.0;
                               // Optional: _updateTotalFromItems();
                            },
                          ),
                        ),
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: () => _removeItem(index),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _loading ? null : _saveTransaction,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(AppLocalizations.of(context).saveTransaction),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
