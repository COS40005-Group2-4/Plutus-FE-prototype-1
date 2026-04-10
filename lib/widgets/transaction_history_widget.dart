import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../transaction_service.dart';
import '../models/transaction_model.dart';
import '../widgets/glass_container.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../services/currency_service.dart';
import '../services/database_service.dart';
import '../utils/date_time_formatter.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';

// Color(0xFF34A853) is AppColors.success

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
  DateTime? _startDate;
  DateTime? _endDate;
  String _dateFilter = 'all'; // 'all', 'today', 'week', 'month', 'custom'

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

    if (kDebugMode) {
      debugPrint('TransactionHistoryWidget: Initialized and listening to stream');
    }
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
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
    if (mounted) setState(() {});
  }

  List<Transaction> _filterTransactionsByDate(List<Transaction> transactions) {
    if (_dateFilter == 'all') {
      return transactions;
    }

    final now = DateTime.now();
    DateTime? filterStart;
    DateTime? filterEnd;

    switch (_dateFilter) {
      case 'today':
        filterStart = DateTime(now.year, now.month, now.day);
        filterEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        filterStart = DateTime(weekStart.year, weekStart.month, weekStart.day);
        filterEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'month':
        filterStart = DateTime(now.year, now.month, 1);
        filterEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'custom':
        filterStart = _startDate;
        filterEnd = _endDate;
        break;
    }

    if (filterStart == null && filterEnd == null) {
      return transactions;
    }

    return transactions.where((tx) {
      if (filterStart != null && tx.dateTime.isBefore(filterStart)) {
        return false;
      }
      if (filterEnd != null && tx.dateTime.isAfter(filterEnd)) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _showDateRangePicker() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    } else {
      // User cancelled, revert to 'all'
      setState(() {
        _dateFilter = 'all';
        _startDate = null;
        _endDate = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return GlassContainer(
          color: AppColors.success,
          opacity: 0.2,
          borderRadius: AppRadius.lg,
          padding: const EdgeInsets.all(AppSpacing.lg),
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

              // Apply date filter
              final filteredTransactions = _filterTransactionsByDate(allTransactions);
              final transactions = filteredTransactions.take(10).toList();

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
                    const SizedBox(width: 4),
                    Tooltip(
                      message: AppLocalizations.of(context).widgetHelpTransactionHistory,
                      child: Icon(
                        Icons.help_outline,
                        size: 14,
                        color: AppColors.textTertiary(Theme.of(context).brightness),
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
                                icon: Icon(Icons.delete, color: AppColors.error, size: 20),
                                onPressed: _deleteSelectedTransactions,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.filter_list, color: Colors.white, size: 20),
                              onSelected: (value) {
                                setState(() {
                                  _dateFilter = value;
                                  if (value == 'custom') {
                                    _showDateRangePicker();
                                  } else {
                                    _startDate = null;
                                    _endDate = null;
                                  }
                                });
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(value: 'all', child: Text('All Time')),
                                PopupMenuItem(value: 'today', child: Text('Today')),
                                PopupMenuItem(value: 'week', child: Text('This Week')),
                                PopupMenuItem(value: 'month', child: Text('This Month')),
                                PopupMenuItem(value: 'custom', child: Text('Custom Range')),
                              ],
                            ),
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
                            color: isSelected ? AppColors.primary : AppColors.textOnDark,
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
                                    fillColor: WidgetStateProperty.resolveWith<Color>(
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
    // Original mode: no conversion
    if (widget.settings.currency.isOriginal) {
      if (mounted) {
        setState(() {
          _convertedAmount = widget.transaction.totalAmount;
          _isLoading = false;
        });
      }
      return;
    }

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
    final brightness = Theme.of(context).brightness;
    if (_isLoading) {
      return const SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(strokeWidth: 1, color: Colors.white),
      );
    }

    final isOriginal = widget.settings.currency.isOriginal;
    final displayCurrency = isOriginal
        ? widget.transaction.currency
        : widget.settings.currency.code;
    final displayAmount = _convertedAmount ?? widget.transaction.totalAmount;
    final formatted = _currencyService.formatCurrency(
      amount: displayAmount,
      currencyCode: displayCurrency,
      );

    return Text(
      '${widget.transaction.isExpense ? '-' : '+'}$formatted',
      style: TextStyle(
        color: widget.transaction.isExpense ? AppColors.negative(brightness) : AppColors.positive(brightness),
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}
