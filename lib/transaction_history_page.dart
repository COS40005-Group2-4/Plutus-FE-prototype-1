import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'transaction_service.dart';
import 'models/transaction_model.dart';
import 'widgets/glass_container.dart';
import 'widgets/export_dialog.dart';
import 'widgets/export_preview_dialog.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'services/currency_service.dart';
import 'services/export_service.dart';
import 'services/user_service.dart';
import 'utils/date_time_formatter.dart';
import 'l10n/app_localizations.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => TransactionHistoryPageState();
}

class TransactionHistoryPageState extends State<TransactionHistoryPage> {
  late TransactionService _service;
  final ExportService _exportService = ExportService();
  final UserService _userService = UserService();
  List<Transaction> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service = TransactionService();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUserId != null) {
      _service.setCurrentUser(authProvider.currentUserId!);
    }
    _loadTransactions();
  }

  void refresh() {
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _loading = true);
    final transactions = await _service.getTransactions();
    setState(() {
      _transactions = transactions;
      _transactions.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      _loading = false;
    });
  }

  Future<void> _showExportDialog() async {
    final options = await showDialog<ExportOptions>(
      context: context,
      builder: (context) => const ExportDialog(),
    );

    if (options == null || !mounted) return;

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
              Expanded(
                child: Text(
                  AppLocalizations.of(context).generatingExport,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 30),
        ),
      );

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUserId != null
          ? await _userService.getUserById(authProvider.currentUserId!)
          : null;

      final result = await _exportService.exportData(
        options: options,
        transactions: _transactions,
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
          content: Text('${AppLocalizations.of(context).exportFailed}$e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context).transactionHistory),
            actions: [
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Export',
                onPressed: _showExportDialog,
              ),
            ],
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : _transactions.isEmpty
                  ? Center(child: Text(AppLocalizations.of(context).noTransactionsFound))
                  : RefreshIndicator(
                      onRefresh: _loadTransactions,
                      child: ListView.builder(
                        key: ValueKey('transaction_list_${settings.currency.code}'),
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = _transactions[index];
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: GlassContainer(
                              borderRadius: 12,
                              opacity: 0.2,
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          transaction.label,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Flexible(
                                        child: _TransactionAmount(
                                          key: ValueKey('${transaction.dateTime}_${settings.currency.code}'),
                                          transaction: transaction,
                                          settings: settings,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    DateTimeFormatter.formatDateTime(
                                      transaction.dateTime,
                                      settings.dateFormat,
                                      settings.timeFormat,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (transaction.postings.length > 1) ...[
                                    const SizedBox(height: 8),
                                    const Divider(),
                                    const Text(
                                      'Postings:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    ...transaction.postings.asMap().entries.map((entry) {
                                      return _PostingRow(
                                        key: ValueKey('${transaction.dateTime}_posting_${entry.key}_${settings.currency.code}'),
                                        posting: entry.value,
                                        settings: settings,
                                      );
                                    }),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        );
      },
    );
  }
}

class _TransactionAmount extends StatefulWidget {
  final Transaction transaction;
  final SettingsProvider settings;

  const _TransactionAmount({
    super.key,
    required this.transaction,
    required this.settings,
  });

  @override
  State<_TransactionAmount> createState() => _TransactionAmountState();
}

class _TransactionAmountState extends State<_TransactionAmount> {
  final CurrencyService _currencyService = CurrencyService();
  double? _convertedAmount;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _convertAmount();
  }

  @override
  void didUpdateWidget(_TransactionAmount oldWidget) {
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
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final displayAmount = _convertedAmount ?? widget.transaction.totalAmount;
    final formatted = _currencyService.formatCurrency(
      amount: displayAmount,
      currencyCode: widget.settings.currency.code,
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${widget.transaction.isExpense ? '-' : '+'}$formatted',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: widget.transaction.isExpense ? Colors.red : Colors.green,
          ),
        ),
        if (widget.transaction.currency != widget.settings.currency.code)
          Text(
            '(${widget.transaction.currency})',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
      ],
    );
  }
}

class _PostingRow extends StatefulWidget {
  final Posting posting;
  final SettingsProvider settings;

  const _PostingRow({
    super.key,
    required this.posting,
    required this.settings,
  });

  @override
  State<_PostingRow> createState() => _PostingRowState();
}

class _PostingRowState extends State<_PostingRow> {
  final CurrencyService _currencyService = CurrencyService();
  double? _convertedAmount;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _convertAmount();
  }

  @override
  void didUpdateWidget(_PostingRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings.currency != widget.settings.currency ||
        oldWidget.posting != widget.posting) {
      _convertAmount();
    }
  }

  Future<void> _convertAmount() async {
    final sourceCurrency = widget.posting.commodity.toUpperCase();
    final targetCurrency = widget.settings.currency.code.toUpperCase();

    // No conversion needed if same currency
    if (sourceCurrency == targetCurrency) {
      if (mounted) {
        setState(() {
          _convertedAmount = widget.posting.amount;
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
        amount: widget.posting.amount.abs(),
        fromCurrency: sourceCurrency,
        toCurrency: targetCurrency,
      );

      if (mounted) {
        setState(() {
          _convertedAmount = widget.posting.amount < 0 ? -converted : converted;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _convertedAmount = widget.posting.amount;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayAmount = _convertedAmount ?? widget.posting.amount;
    final formatted = _currencyService.formatCurrency(
      amount: displayAmount.abs(),
      currencyCode: widget.settings.currency.code,
      );

    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              widget.posting.account,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_isLoading)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1),
            )
          else
            Text(
              '${displayAmount >= 0 ? '+' : '-'}$formatted',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
        ],
      ),
    );
  }
}


