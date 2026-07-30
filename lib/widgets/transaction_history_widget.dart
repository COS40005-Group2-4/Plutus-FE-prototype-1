import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../providers/auth_notifier.dart';
import '../providers/settings_notifier.dart';
import '../services/currency_service.dart';
import '../services/interfaces/interfaces.dart';
import '../di/service_locator.dart';
import '../utils/date_time_formatter.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/plutus_tokens.dart';
import 'core/app_card.dart';

class TransactionHistoryWidget extends ConsumerStatefulWidget {
  const TransactionHistoryWidget({super.key});

  @override
  ConsumerState<TransactionHistoryWidget> createState() =>
      _TransactionHistoryWidgetState();
}

class _TransactionHistoryWidgetState extends ConsumerState<TransactionHistoryWidget> {
  late ITransactionService _transactionService;
  late IDatabaseService _databaseService;
  bool _isEditMode = false;
  final Set<dynamic> _selectedTransactionIds = {};
  DateTime? _startDate;
  DateTime? _endDate;
  String _dateFilter = 'all'; // 'all', 'today', 'week', 'month', 'custom'

  @override
  void initState() {
    super.initState();
    _transactionService = sl<ITransactionService>();
    _databaseService = sl<IDatabaseService>();
    final currentUserId = ref.read(authNotifierProvider.notifier).currentUserId;
    if (currentUserId != null) {
      _transactionService.setCurrentUser(currentUserId);
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
            backgroundColor: context.tokens.error.dot,
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
    final settings = ref.watch(settingsNotifierProvider);
    final brightness = Theme.of(context).brightness;
    final PlutusTokens t = context.tokens;
    return AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
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
                    AppLocalizations.of(context).noTransactionHistory,
                    style: TextStyle(color: t.text, fontSize: 14),
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
                          style: TextStyle(
                          color: t.text,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Tooltip(
                      message: AppLocalizations.of(context).widgetHelpTransactionHistory,
                      child: Icon(
                        Icons.help_outline,
                        size: 14,
                        color: t.textMuted,
                      ),
                    ),
                      if (_isEditMode)
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.close, color: t.text, size: 20),
                              onPressed: () {
                                setState(() {
                                  _isEditMode = false;
                                  _selectedTransactionIds.clear();
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            if (_selectedTransactionIds.isNotEmpty)
                              IconButton(
                                icon: Icon(Icons.delete, color: t.error.text, size: 20),
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
                              icon: Icon(Icons.filter_list, color: t.text, size: 20),
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
                              icon: Icon(Icons.edit, color: t.text, size: 20),
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
                    const SizedBox(height: AppSpacing.sm),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                      separatorBuilder: (context, index) => Divider(height: 1, color: t.border),
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
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: isSelected
                                ? BoxDecoration(
                                    color: brightness == Brightness.dark
                                        ? Color.alphaBlend(t.goldWeak, t.surface)
                                        : t.goldWeak,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: t.gold),
                                  )
                                : null,
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
                                      (states) => t.text,
                                    ),
                                  ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        transaction.label,
                                        style: TextStyle(
                                          color: t.text,
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
                                        style: TextStyle(
                                          color: t.textSecondary,
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
  }
}

class _DashboardTransactionAmount extends StatefulWidget {
  final Transaction transaction;
  final SettingsState settings;

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
    final PlutusTokens t = context.tokens;
    if (_isLoading) {
      return SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(strokeWidth: 1, color: t.text),
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
      textAlign: TextAlign.right,
      style: AppTextStyles.numericStyle.copyWith(
        color: widget.transaction.isExpense ? t.error.text : t.success.text,
        fontSize: 14,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}
