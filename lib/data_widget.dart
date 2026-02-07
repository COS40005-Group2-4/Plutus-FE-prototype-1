import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'storage.dart';
import 'transaction_service.dart';
import 'models/transaction_model.dart';
import 'widgets/glass_container.dart';
import 'widgets/export_dialog.dart';
import 'widgets/export_preview_dialog.dart';
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
    "budget": (l) => const BudgetTrackingWidget(),
    "history": (l) => const TransactionHistoryWidget(),
    "import": (l) => const ReportImportWidget(),
    "export": (l) => const ReportExportWidget(),
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

  @override
  void initState() {
    super.initState();
    _transactionService = TransactionService();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUserId != null) {
      _transactionService.setCurrentUser(authProvider.currentUserId!);
    }
    // Load initial transactions on next frame to ensure stream subscription is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _transactionService.notifyTransactionUpdate();
    });
  }

  @override
  void dispose() {
    // Don't dispose - service is a singleton
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
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                );
              }

              final transactions = snapshot.data!;

              return _BudgetContent(
                key: ValueKey('budget_${settings.currency.code}'),
                transactions: transactions,
                settings: settings,
              );
            },
          ),
        );
      },
    );
  }
}

class _BudgetContent extends StatefulWidget {
  final List<Transaction> transactions;
  final SettingsProvider settings;

  const _BudgetContent({
    super.key,
    required this.transactions,
    required this.settings,
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

      // Convert if needed
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
          // If conversion fails, use original amount
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
    final currencyService = CurrencyService();

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text(
          AppLocalizations.of(context).widgetBudgetOverview,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        GlassContainer(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          opacity: 0.1,
          borderRadius: 8,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${AppLocalizations.of(context).income}:',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    currencyService.formatCurrency(
                      amount: _totalIncome,
                      currencyCode: widget.settings.currency.code,
                      symbol: widget.settings.currency.symbol,
                    ),
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${AppLocalizations.of(context).expense}:',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    currencyService.formatCurrency(
                      amount: _totalExpense,
                      currencyCode: widget.settings.currency.code,
                      symbol: widget.settings.currency.symbol,
                    ),
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Balance:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    currencyService.formatCurrency(
                      amount: balance,
                      currencyCode: widget.settings.currency.code,
                      symbol: widget.settings.currency.symbol,
                    ),
                    style: TextStyle(
                      color: balance >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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

              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context).widgetRecentTransactions,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
                  Expanded(
                    child: ListView.builder(
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
                  ),
                ],
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Generating export...'),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
    );
  }
}
