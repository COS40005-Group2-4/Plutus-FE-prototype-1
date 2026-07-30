import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../widgets/export_dialog.dart';
import '../widgets/export_preview_dialog.dart';
import '../widgets/transaction_detail_dialog.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/plutus_tokens.dart';
import '../providers/auth_notifier.dart';
import '../providers/settings_notifier.dart';
import '../services/currency_service.dart';
import '../services/export_service.dart';
import '../services/user_service.dart';
import '../services/interfaces/interfaces.dart';
import '../di/service_locator.dart';
import '../utils/date_time_formatter.dart';
import '../l10n/app_localizations.dart';

enum _TransactionTypeFilter { all, income, expense }

class TransactionHistoryPage extends ConsumerStatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  ConsumerState<TransactionHistoryPage> createState() => TransactionHistoryPageState();
}

class TransactionHistoryPageState extends ConsumerState<TransactionHistoryPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late ITransactionService _service;
  final ExportService _exportService = ExportService();
  final UserService _userService = UserService();
  List<Transaction> _transactions = [];
  bool _loading = true;
  _TransactionTypeFilter _filter = _TransactionTypeFilter.all;

  @override
  void initState() {
    super.initState();
    _service = sl<ITransactionService>();
    final authNotifier = ref.read(authNotifierProvider.notifier);
    if (authNotifier.currentUserId != null) {
      _service.setCurrentUser(authNotifier.currentUserId!);
    }
    _loadTransactions();
  }

  void refresh() {
    _loadTransactions();
  }

  List<Transaction> get _filteredTransactions {
    switch (_filter) {
      case _TransactionTypeFilter.income:
        return _transactions.where((tx) => !tx.isExpense).toList();
      case _TransactionTypeFilter.expense:
        return _transactions.where((tx) => tx.isExpense).toList();
      case _TransactionTypeFilter.all:
        return _transactions;
    }
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

      final authNotifier = ref.read(authNotifierProvider.notifier);
      final locale = AppLocalizations.of(context).locale.languageCode;
      final user = authNotifier.currentUserId != null
          ? await _userService.getUserById(authNotifier.currentUserId!)
          : null;

      final result = await _exportService.exportData(
        options: options,
        transactions: _transactions,
        user: user,
        locale: locale,
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
      final PlutusTokens t = context.tokens;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context).exportFailed}$e'),
          backgroundColor: t.error.dot,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Widget _buildFilterChips(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.componentLg,
        vertical: AppSpacing.componentSm,
      ),
      child: Row(
        children: [
          _FilterChip(
            label: l10n.all,
            selected: _filter == _TransactionTypeFilter.all,
            onTap: () => setState(() => _filter = _TransactionTypeFilter.all),
          ),
          const SizedBox(width: AppSpacing.componentSm),
          _FilterChip(
            label: l10n.income,
            selected: _filter == _TransactionTypeFilter.income,
            onTap: () => setState(() => _filter = _TransactionTypeFilter.income),
          ),
          const SizedBox(width: AppSpacing.componentSm),
          _FilterChip(
            label: l10n.expense,
            selected: _filter == _TransactionTypeFilter.expense,
            onTap: () => setState(() => _filter = _TransactionTypeFilter.expense),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final settings = ref.watch(settingsNotifierProvider);
    final PlutusTokens t = context.tokens;
    final l10n = AppLocalizations.of(context);
    final filteredTransactions = _filteredTransactions;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.transactionHistory),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: l10n.export,
            onPressed: _showExportDialog,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterChips(l10n),
                Expanded(
                  child: filteredTransactions.isEmpty
                      ? Center(child: Text(l10n.noTransactionsFound))
                      : RefreshIndicator(
                          onRefresh: _loadTransactions,
                          child: ListView.separated(
                            key: ValueKey(
                              'transaction_list_${settings.currency.code}_${_filter.name}',
                            ),
                            itemCount: filteredTransactions.length,
                            separatorBuilder: (_, _) => Divider(height: 1, color: t.border),
                            itemBuilder: (context, index) {
                              final transaction = filteredTransactions[index];

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => TransactionDetailDialog(
                                        transaction: transaction,
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.componentLg,
                                      vertical: AppSpacing.componentSm,
                                    ),
                                    child: Row(
                                      children: [
                                        // Type icon
                                        Icon(
                                          transaction.isExpense
                                              ? Icons.arrow_downward
                                              : Icons.arrow_upward,
                                          color: transaction.isExpense ? t.error.dot : t.success.dot,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        // Label + date
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                transaction.label,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: t.text,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                DateTimeFormatter.formatDateTimeShort(
                                                  transaction.dateTime,
                                                  settings.dateFormat,
                                                  settings.timeFormat,
                                                ),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: t.textMuted,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Amount
                                        _TransactionAmount(
                                          key: ValueKey('${transaction.dateTime}_${settings.currency.code}'),
                                          transaction: transaction,
                                          settings: settings,
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.chevron_right,
                                          color: t.textMuted,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final PlutusTokens t = context.tokens;
    return Material(
      color: selected ? t.goldSelectedFill : t.surfaceSubtle,
      borderRadius: AppRadius.borderPill,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderPill,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.componentMd,
            vertical: AppSpacing.componentXs,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderPill,
            border: selected ? Border.all(color: t.gold) : null,
          ),
          child: Text(
            label,
            style: AppTextStyles.labelStyle.copyWith(
              color: selected ? t.goldText : t.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionAmount extends StatefulWidget {
  final Transaction transaction;
  final SettingsState settings;

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
    // Original mode: no conversion, show transaction's own currency
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
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${widget.transaction.isExpense ? '-' : '+'}$formatted',
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.numericStyle.copyWith(
            fontSize: 16,
            color: widget.transaction.isExpense ? t.error.text : t.success.text,
          ),
        ),
        if (!isOriginal && widget.transaction.currency != widget.settings.currency.code)
          Text(
            '(${widget.transaction.currency})',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: t.textMuted,
            ),
          ),
      ],
    );
  }
}
