import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/bill_model.dart';
import '../services/bill_service.dart';
import '../services/database_service.dart';
import '../services/currency_service.dart';
import '../transaction_service.dart';
import '../providers/auth_notifier.dart';
import '../providers/settings_notifier.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';
import 'glass_container.dart';
import 'chart_theme.dart';

class UpcomingBillsWidget extends ConsumerStatefulWidget {
  const UpcomingBillsWidget({super.key});

  @override
  ConsumerState<UpcomingBillsWidget> createState() => _UpcomingBillsWidgetState();
}

class _UpcomingBillsWidgetState extends ConsumerState<UpcomingBillsWidget> {
  late BillService _billService;
  late TransactionService _transactionService;
  int _daysFilter = 30;

  @override
  void initState() {
    super.initState();
    _billService = BillService();
    _transactionService = TransactionService();
    final currentUserId = ref.read(authNotifierProvider.notifier).currentUserId;
    if (currentUserId != null) {
      _billService.setCurrentUser(currentUserId);
      _transactionService.setCurrentUser(currentUserId);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _billService.notifyBillUpdate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);
    return GlassContainer(
          color: AppColors.billsAccent,
          opacity: 0.2,
          borderRadius: AppRadius.lg,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder<List<Bill>>(
                  stream: _billService.billStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          AppLocalizations.of(context).noBillsUpcoming,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      );
                    }

                    // Filter out paid bills
                    final bills = _filterBills(snapshot.data!.where((b) => !b.isPaid).toList());

                    return _BillsContent(
                      bills: bills,
                      settings: settings,
                      daysFilter: _daysFilter,
                      onPayBill: _handlePayBill,
                    );
                  },
                ),
              ),
            ],
          ),
        );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context).upcomingBills,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Tooltip(
              message: AppLocalizations.of(context).widgetHelpBills,
              child: Icon(
                Icons.help_outline,
                size: 14,
                color: AppColors.textTertiary(Theme.of(context).brightness),
              ),
            ),
          ],
        ),
        Row(
          children: [
            PopupMenuButton<int>(
              icon: const Icon(Icons.filter_list, color: Colors.white, size: 20),
              onSelected: (value) {
                setState(() => _daysFilter = value);
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 7, child: Text('Next 7 days')),
                PopupMenuItem(value: 30, child: Text('Next 30 days')),
                PopupMenuItem(value: 90, child: Text('Next 90 days')),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white, size: 20),
              onPressed: () => _showBillEditor(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ],
    );
  }

  List<Bill> _filterBills(List<Bill> bills) {
    final endDate = DateTime.now().add(Duration(days: _daysFilter));

    return bills.where((bill) {
      // Overdue bills are always shown regardless of the filter window
      return bill.isOverdue || !bill.dueDate.isAfter(endDate);
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  Future<void> _showBillEditor(BuildContext context) async {
    // Get all bills (including paid ones for editing)
    final allBills = await _billService.getBills();

    if (!context.mounted) return;
    if (allBills.isEmpty) {
      // No bills exist, show add dialog
      await showDialog(
        context: context,
        builder: (context) => _BillEditorDialog(
          billService: _billService,
        ),
      );
    } else {
      // Show bill selection dialog
      await showDialog(
        context: context,
        builder: (context) => _BillSelectorDialog(
          bills: allBills,
          billService: _billService,
        ),
      );
    }
  }

  Future<void> _handlePayBill(Bill bill) async {
    if (bill.id == null) return;

    final currentUserId = ref.read(authNotifierProvider.notifier).currentUserId;
    if (currentUserId == null) return;

    // Create transaction in database
    final now = DateTime.now();
    final transaction = {
      'transaction_id': 'bill_${bill.id}_${now.millisecondsSinceEpoch}',
      'type': 'expense',
      'amount': bill.amount,
      'currency': bill.currency,
      'category': bill.category ?? 'Expenses:Bills',
      'description': 'Bill payment: ${bill.name}',
      'payee': bill.name,
      'date': now.toIso8601String(),
      'account': 'Assets:Cash',
      'postings': [
        {
          'account': 'Assets:Cash',
          'amount': -bill.amount,
          'commodity': bill.currency,
        },
        {
          'account': bill.category ?? 'Expenses:Bills',
          'amount': bill.amount,
          'commodity': bill.currency,
        },
      ],
    };

    final db = DatabaseService();
    await db.insertTransaction(currentUserId, transaction);

    // Mark bill as paid
    await _billService.markBillAsPaid(bill.id!);

    // Notify transaction service
    _transactionService.notifyTransactionUpdate();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bill "${bill.name}" marked as paid')),
      );
    }
  }
}

class _BillsContent extends StatefulWidget {
  final List<Bill> bills;
  final SettingsState settings;
  final int daysFilter;
  final Function(Bill) onPayBill;

  const _BillsContent({
    required this.bills,
    required this.settings,
    required this.daysFilter,
    required this.onPayBill,
  });

  @override
  State<_BillsContent> createState() => _BillsContentState();
}

class _BillsContentState extends State<_BillsContent> {
  final CurrencyService _currencyService = CurrencyService();
  final Map<String, double> _convertedAmounts = {};
  final Set<int> _animatingBills = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _convertAmounts();
  }

  @override
  void didUpdateWidget(_BillsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings.currency != widget.settings.currency ||
        oldWidget.bills != widget.bills) {
      _convertAmounts();
    }
  }

  Future<void> _convertAmounts() async {
    setState(() => _isLoading = true);
    
    _convertedAmounts.clear();
    
    for (var bill in widget.bills) {
      if (bill.currency == widget.settings.currency.code) {
        _convertedAmounts[bill.id.toString()] = bill.amount;
      } else {
        try {
          final converted = await _currencyService.convert(
            amount: bill.amount,
            fromCurrency: bill.currency,
            toCurrency: widget.settings.currency.code,
          );
          _convertedAmounts[bill.id.toString()] = converted;
        } catch (e) {
          _convertedAmounts[bill.id.toString()] = bill.amount;
        }
      }
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final totalDue = widget.bills
        .where((b) => !b.isPaid)
        .fold(0.0, (sum, bill) {
          final converted = _convertedAmounts[bill.id.toString()] ?? bill.amount;
          return sum + converted;
        });

    return Column(
      children: [
        _buildSummary(totalDue),
        if (widget.bills.length > 1) _buildBillsBarChart(),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: widget.bills.length,
            itemBuilder: (context, index) {
              final bill = widget.bills[index];
              final convertedAmount = _convertedAmounts[bill.id.toString()] ?? bill.amount;
              final isAnimating = _animatingBills.contains(bill.id);
              return _buildBillItem(context, bill, convertedAmount, isAnimating);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBillsBarChart() {
    final now = DateTime.now();
    // Group bills by week number within the filter window
    final Map<int, double> weeklyTotals = {};
    for (var bill in widget.bills) {
      final daysFromNow = bill.dueDate.difference(now).inDays;
      final weekNum = bill.isOverdue ? 0 : (daysFromNow ~/ 7) + 1;
      final clamped = weekNum.clamp(0, 4);
      final amount = _convertedAmounts[bill.id.toString()] ?? bill.amount;
      weeklyTotals[clamped] = (weeklyTotals[clamped] ?? 0) + amount;
    }

    if (weeklyTotals.isEmpty) return const SizedBox.shrink();

    final maxVal = weeklyTotals.values.fold(0.0, (a, b) => a > b ? a : b);
    final labels = ['Overdue', 'Wk 1', 'Wk 2', 'Wk 3', 'Wk 4'];
    final colors = [AppColors.error, AppColors.warning, AppColors.primary, AppColors.primary, AppColors.primary];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 80,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxVal * 1.3,
            minY: 0,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${labels[group.x]}\n${PlutusChartStyle.formatCompactCurrency(rod.toY)}',
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
                    final idx = value.toInt();
                    if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                    if (!weeklyTotals.containsKey(idx)) return const SizedBox.shrink();
                    return Text(
                      labels[idx],
                      style: const TextStyle(color: Colors.white54, fontSize: 9),
                    );
                  },
                ),
              ),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: weeklyTotals.entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value,
                    color: colors[entry.key.clamp(0, 4)].withValues(alpha:0.7),
                    width: 20,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSummary(double totalDue) {
    final format = widget.settings.currency == AppCurrency.vnd
        ? NumberFormat("#,##0", "en_US")
        : NumberFormat("#,##0.00", "en_US");
    
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      opacity: 0.1,
      borderRadius: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${AppLocalizations.of(context).totalDue} (${widget.daysFilter}d):',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            '${widget.settings.currency.symbol}${format.format(totalDue)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillItem(BuildContext context, Bill bill, double convertedAmount, bool isAnimating) {
    final now = DateTime.now();
    final daysUntilDue = bill.dueDate.difference(now).inDays;
    
    Color dateColor;
    if (bill.isOverdue) {
      dateColor = AppColors.error;
    } else if (daysUntilDue <= 3) {
      dateColor = AppColors.error;
    } else {
      dateColor = const Color(0xFF6050dc);
    }

    // Get currency symbol for the bill's original currency
    final billCurrency = AppCurrency.fromCode(bill.currency);

    return AnimatedOpacity(
      opacity: isAnimating ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.md),
          color: Colors.white,
          opacity: 0.05,
          borderRadius: 8,
          child: Row(
            children: [
              // Date indicator
              Container(
                width: 50,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: dateColor.withValues(alpha:0.2),
                  borderRadius: AppRadius.borderSm,
                  border: Border.all(color: dateColor.withValues(alpha:0.5)),
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('MMM').format(bill.dueDate),
                      style: TextStyle(
                        color: dateColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('dd').format(bill.dueDate),
                      style: TextStyle(
                        color: dateColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Bill details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        // Show converted amount with settings currency
                        Text(
                          '${widget.settings.currency.symbol}${_formatAmount(convertedAmount, widget.settings.currency)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        // Show original amount if different currency
                        if (bill.currency != widget.settings.currency.code) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${billCurrency.symbol}${_formatAmount(bill.amount, billCurrency)})',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        if (bill.isOverdue)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha:0.25),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.error.withValues(alpha:0.6)),
                            ),
                            child: const Text(
                              'OVERDUE',
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else if (bill.recurrence != BillRecurrence.oneTime)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha:0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getRecurrenceLabel(bill.recurrence),
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 9,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Pay button with animation
              if (!bill.isPaid)
                ElevatedButton(
                  onPressed: () => _handlePayBill(bill),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success.withValues(alpha:0.8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Pay', style: TextStyle(fontSize: 11)),
                )
              else
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Icon(
                        Icons.check_circle,
                        color: AppColors.success.withValues(alpha:value),
                        size: 20,
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePayBill(Bill bill) async {
    if (bill.id == null) return;

    // Start animation
    setState(() {
      _animatingBills.add(bill.id!);
    });

    // Wait for animation to complete
    await Future.delayed(const Duration(milliseconds: 300));

    // Call the parent's pay handler
    await widget.onPayBill(bill);

    // Remove from animating set
    if (mounted) {
      setState(() {
        _animatingBills.remove(bill.id!);
      });
    }
  }

  String _getRecurrenceLabel(BillRecurrence recurrence) {
    switch (recurrence) {
      case BillRecurrence.monthly:
        return 'Monthly';
      case BillRecurrence.quarterly:
        return 'Quarterly';
      case BillRecurrence.yearly:
        return 'Yearly';
      default:
        return '';
    }
  }

  String _formatAmount(double amount, AppCurrency currency) {
    if (currency == AppCurrency.vnd) {
      return NumberFormat("#,##0", "en_US").format(amount);
    } else {
      return NumberFormat("#,##0.00", "en_US").format(amount);
    }
  }
}

class _BillEditorDialog extends StatefulWidget {
  final BillService billService;
  final Bill? bill;

  const _BillEditorDialog({
    required this.billService,
    this.bill,
  });

  @override
  State<_BillEditorDialog> createState() => _BillEditorDialogState();
}

class _BillEditorDialogState extends State<_BillEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _categoryController;
  late TextEditingController _notesController;
  late DateTime _dueDate;
  late BillRecurrence _recurrence;
  String _currency = 'VND';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.bill?.name ?? '');
    _amountController = TextEditingController(
      text: widget.bill?.amount.toString() ?? '',
    );
    _categoryController = TextEditingController(text: widget.bill?.category ?? '');
    _notesController = TextEditingController(text: widget.bill?.notes ?? '');
    _dueDate = widget.bill?.dueDate ?? DateTime.now().add(const Duration(days: 7));
    _recurrence = widget.bill?.recurrence ?? BillRecurrence.oneTime;
    _currency = widget.bill?.currency ?? 'VND';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.bill == null ? 'Add Bill' : 'Edit Bill'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Bill Name'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (double.tryParse(value!) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _currency,
                decoration: const InputDecoration(labelText: 'Currency'),
                items: ['VND', 'USD', 'EUR']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) => setState(() => _currency = value!),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Due Date'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_dueDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (picked != null) {
                    setState(() => _dueDate = picked);
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<BillRecurrence>(
                initialValue: _recurrence,
                decoration: const InputDecoration(labelText: 'Recurrence'),
                items: BillRecurrence.values
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(_getRecurrenceLabel(r)),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _recurrence = value!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category (optional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveBill,
          child: const Text('Save'),
        ),
      ],
    );
  }

  String _getRecurrenceLabel(BillRecurrence recurrence) {
    switch (recurrence) {
      case BillRecurrence.oneTime:
        return 'One-time';
      case BillRecurrence.monthly:
        return 'Monthly';
      case BillRecurrence.quarterly:
        return 'Quarterly';
      case BillRecurrence.yearly:
        return 'Yearly';
    }
  }

  Future<void> _saveBill() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final bill = Bill(
        id: widget.bill?.id,
        name: _nameController.text,
        amount: double.parse(_amountController.text),
        currency: _currency,
        dueDate: _dueDate,
        recurrence: _recurrence,
        category: _categoryController.text.isEmpty ? null : _categoryController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (widget.bill == null) {
        await widget.billService.addBill(bill);
      } else {
        await widget.billService.updateBill(bill);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bill saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving bill: $e')),
        );
      }
    }
  }
}


class _BillSelectorDialog extends StatelessWidget {
  final List<Bill> bills;
  final BillService billService;

  const _BillSelectorDialog({
    required this.bills,
    required this.billService,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manage Bills'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: bills.length,
                itemBuilder: (context, index) {
                  final bill = bills[index];
                  final billCurrency = AppCurrency.fromCode(bill.currency);
                  final format = billCurrency == AppCurrency.vnd
                      ? NumberFormat("#,##0", "en_US")
                      : NumberFormat("#,##0.00", "en_US");
                  
                  return ListTile(
                    leading: Icon(
                      bill.isPaid ? Icons.check_circle : Icons.receipt_long,
                      color: bill.isPaid
                          ? AppColors.success
                          : bill.isOverdue
                              ? AppColors.error
                              : AppColors.warning,
                    ),
                    title: Text(bill.name),
                    subtitle: Text(
                      '${billCurrency.symbol}${format.format(bill.amount)} - ${DateFormat('dd/MM/yyyy').format(bill.dueDate)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await showDialog(
                              context: context,
                              builder: (context) => _BillEditorDialog(
                                billService: billService,
                                bill: bill,
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, size: 20, color: AppColors.error),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Bill'),
                                content: Text('Are you sure you want to delete "${bill.name}"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: Text('Delete', style: TextStyle(color: AppColors.error)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && bill.id != null) {
                              await billService.deleteBill(bill.id!);
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            Navigator.of(context).pop();
            await showDialog(
              context: context,
              builder: (context) => _BillEditorDialog(
                billService: billService,
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Add New'),
        ),
      ],
    );
  }
}
