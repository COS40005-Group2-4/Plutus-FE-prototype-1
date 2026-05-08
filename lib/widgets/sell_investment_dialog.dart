import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models/investment_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

typedef OnConfirmSale = Future<void> Function({
  required double quantity,
  required double pricePerUnit,
  required DateTime date,
  required String cashAccount,
  String? notes,
});

/// Modal that records a partial or full sale of [investment].
///
/// Computes a live preview of proceeds and realised gain/loss based on the
/// investment's current average unit cost and the user's inputs.
class SellInvestmentDialog extends StatefulWidget {
  final InvestmentModel investment;
  final OnConfirmSale onConfirm;

  const SellInvestmentDialog({
    super.key,
    required this.investment,
    required this.onConfirm,
  });

  @override
  State<SellInvestmentDialog> createState() => _SellInvestmentDialogState();
}

class _SellInvestmentDialogState extends State<SellInvestmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();
  final _accountController = TextEditingController(text: 'Assets:Cash');
  final _notesController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.investment.currentPrice != null) {
      _priceController.text = widget.investment.currentPrice!.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    _accountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double? get _qty => double.tryParse(_qtyController.text.trim());
  double? get _price => double.tryParse(_priceController.text.trim());

  double? get _proceeds {
    final q = _qty;
    final p = _price;
    if (q == null || p == null) return null;
    return q * p;
  }

  double? get _realizedGain {
    final q = _qty;
    final p = _price;
    if (q == null || p == null) return null;
    return (p - widget.investment.averageUnitCost) * q;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await widget.onConfirm(
        quantity: _qty!,
        pricePerUnit: _price!,
        date: _date,
        cashAccount: _accountController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final inv = widget.investment;
    final symbol = inv.getCurrencySymbol();

    return AlertDialog(
      title: Text('${l.investmentSellTitle} — ${inv.assetName}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${l.investmentQuantityHeld}: ${inv.quantity}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '${l.investmentAvgUnitCost}: $symbol${inv.averageUnitCost.toStringAsFixed(4)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _qtyController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(labelText: l.investmentSellQuantity),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final q = double.tryParse((v ?? '').trim());
                  if (q == null || q <= 0) return l.investmentGreaterThanZero;
                  if (q > inv.quantity + 1e-9) {
                    return l.investmentSellOversell(inv.quantity.toString());
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(labelText: l.investmentSellPricePerUnit),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final p = double.tryParse((v ?? '').trim());
                  if (p == null || p <= 0) return l.investmentGreaterThanZero;
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(labelText: l.investmentSellDate),
                  child: Text(
                    '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _accountController,
                decoration: InputDecoration(labelText: l.investmentSellDestination),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l.investmentSelectCashAccount : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(labelText: l.investmentSellNotes),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_proceeds != null && _realizedGain != null) ...[
                _PreviewRow(
                  label: l.investmentSellProceeds,
                  value: '$symbol${_proceeds!.toStringAsFixed(2)}',
                ),
                _PreviewRow(
                  label: _realizedGain! >= 0
                      ? l.investmentSellRealizedGain
                      : l.investmentSellRealizedLoss,
                  value: '$symbol${_realizedGain!.abs().toStringAsFixed(2)}',
                  color: _realizedGain! >= 0 ? AppColors.success : AppColors.error,
                ),
                _PreviewRow(
                  label: l.investmentSellRemaining,
                  value: (inv.quantity - (_qty ?? 0)).toStringAsFixed(4),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l.investmentSellConfirm),
        ),
      ],
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _PreviewRow({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
