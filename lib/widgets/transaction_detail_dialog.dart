import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../providers/settings_notifier.dart';
import '../services/currency_service.dart';
import '../utils/date_time_formatter.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import 'glass_container.dart';

class TransactionDetailDialog extends ConsumerWidget {
  final Transaction transaction;

  const TransactionDetailDialog({super.key, required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final l10n = AppLocalizations.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassContainer(
        borderRadius: 16,
        opacity: 0.25,
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      l10n.transactionDetails,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Amount
              Center(
                child: _DetailAmount(
                  transaction: transaction,
                  settings: settings,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Info rows
              _InfoRow(label: l10n.payee, value: transaction.payee),
              if (transaction.description.isNotEmpty)
                _InfoRow(label: l10n.description, value: transaction.description),
              _InfoRow(
                label: l10n.date,
                value: DateTimeFormatter.formatDateTime(
                  transaction.dateTime,
                  settings.dateFormat,
                  settings.timeFormat,
                ),
              ),
              _InfoRow(
                label: l10n.type,
                value: transaction.isExpense ? l10n.expense : l10n.income,
              ),

              // Postings
              if (transaction.postings.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.postings,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...transaction.postings.asMap().entries.map((entry) {
                  return _PostingDetailRow(
                    key: ValueKey('detail_posting_${entry.key}_${settings.currency.code}'),
                    posting: entry.value,
                    settings: settings,
                  );
                }),
              ],

              const SizedBox(height: AppSpacing.lg),
              // Close button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    l10n.close,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailAmount extends StatefulWidget {
  final Transaction transaction;
  final SettingsState settings;

  const _DetailAmount({required this.transaction, required this.settings});

  @override
  State<_DetailAmount> createState() => _DetailAmountState();
}

class _DetailAmountState extends State<_DetailAmount> {
  final CurrencyService _currencyService = CurrencyService();
  double? _convertedAmount;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _convertAmount();
  }

  @override
  void didUpdateWidget(_DetailAmount oldWidget) {
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

    final source = widget.transaction.currency.toUpperCase();
    final target = widget.settings.currency.code.toUpperCase();

    if (source == target) {
      if (mounted) {
        setState(() {
          _convertedAmount = widget.transaction.totalAmount;
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    try {
      final converted = await _currencyService.convert(
        amount: widget.transaction.totalAmount,
        fromCurrency: source,
        toCurrency: target,
      );
      if (mounted) {
        setState(() {
          _convertedAmount = converted;
          _isLoading = false;
        });
      }
    } catch (_) {
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
        width: 20, height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    }

    final isOriginal = widget.settings.currency.isOriginal;
    final displayCurrency = isOriginal
        ? widget.transaction.currency
        : widget.settings.currency.code;
    final amount = _convertedAmount ?? widget.transaction.totalAmount;
    final formatted = _currencyService.formatCurrency(
      amount: amount,
      currencyCode: displayCurrency,
    );

    return Column(
      children: [
        Text(
          '${widget.transaction.isExpense ? '-' : '+'}$formatted',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: widget.transaction.isExpense ? AppColors.negative(Theme.of(context).brightness) : AppColors.positive(Theme.of(context).brightness),
          ),
        ),
        if (!isOriginal && widget.transaction.currency != widget.settings.currency.code)
          Text(
            '(${widget.transaction.currency})',
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
      ],
    );
  }
}

class _PostingDetailRow extends StatefulWidget {
  final Posting posting;
  final SettingsState settings;

  const _PostingDetailRow({
    super.key,
    required this.posting,
    required this.settings,
  });

  @override
  State<_PostingDetailRow> createState() => _PostingDetailRowState();
}

class _PostingDetailRowState extends State<_PostingDetailRow> {
  final CurrencyService _currencyService = CurrencyService();
  double? _convertedAmount;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _convertAmount();
  }

  @override
  void didUpdateWidget(_PostingDetailRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings.currency != widget.settings.currency ||
        oldWidget.posting != widget.posting) {
      _convertAmount();
    }
  }

  Future<void> _convertAmount() async {
    // Original mode: no conversion
    if (widget.settings.currency.isOriginal) {
      if (mounted) {
        setState(() {
          _convertedAmount = widget.posting.amount;
          _isLoading = false;
        });
      }
      return;
    }

    final source = widget.posting.commodity.toUpperCase();
    final target = widget.settings.currency.code.toUpperCase();

    if (source == target) {
      if (mounted) {
        setState(() {
          _convertedAmount = widget.posting.amount;
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    try {
      final converted = await _currencyService.convert(
        amount: widget.posting.amount.abs(),
        fromCurrency: source,
        toCurrency: target,
      );
      if (mounted) {
        setState(() {
          _convertedAmount = widget.posting.amount < 0 ? -converted : converted;
          _isLoading = false;
        });
      }
    } catch (_) {
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
    final isOriginal = widget.settings.currency.isOriginal;
    final displayCurrency = isOriginal
        ? widget.posting.commodity
        : widget.settings.currency.code;
    final formatted = _isLoading
        ? '...'
        : _currencyService.formatCurrency(
            amount: (_convertedAmount ?? widget.posting.amount).abs(),
            currencyCode: displayCurrency,
          );

    final isNegative = (widget.posting.amount < 0);
    final sign = isNegative ? '-' : '+';

    return GlassContainer(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      opacity: 0.1,
      borderRadius: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              widget.posting.account,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$sign$formatted',
            style: TextStyle(
              color: isNegative ? AppColors.negative(Theme.of(context).brightness) : AppColors.positive(Theme.of(context).brightness),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
