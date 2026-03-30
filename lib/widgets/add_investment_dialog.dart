import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'glass_container.dart';
import '../l10n/app_localizations.dart';
import '../models/investment_model.dart';
import '../theme/app_colors.dart';

/// Dialog for adding a new investment
class AddInvestmentDialog extends StatefulWidget {
  final Function(
    AssetType assetType,
    String assetName,
    double quantity,
    double purchaseValue,
    Currency currency,
    DateTime purchaseDate,
  ) onSave;

  const AddInvestmentDialog({
    super.key,
    required this.onSave,
  });

  @override
  State<AddInvestmentDialog> createState() => _AddInvestmentDialogState();
}

class _AddInvestmentDialogState extends State<AddInvestmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _assetNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _purchaseValueController = TextEditingController();
  
  AssetType _assetType = AssetType.stock;
  Currency _currency = Currency.usd;
  DateTime _purchaseDate = DateTime.now();

  @override
  void dispose() {
    _assetNameController.dispose();
    _quantityController.dispose();
    _purchaseValueController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final assetName = _assetNameController.text.trim();
    final quantity = double.parse(_quantityController.text.trim());
    final purchaseValue = double.parse(_purchaseValueController.text.trim());

    widget.onSave(
      _assetType,
      assetName,
      quantity,
      purchaseValue,
      _currency,
      _purchaseDate,
    );
    Navigator.of(context).pop();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _purchaseDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        child: GlassContainer(
          borderRadius: 16,
          blur: 15.0,
          opacity: isDark ? 0.35 : 0.1,
          color: isDark ? AppColors.surfaceDark : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.addInvestment,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Asset Type Dropdown
                  DropdownButtonFormField<AssetType>(
                    initialValue: _assetType,
                    decoration: InputDecoration(
                      labelText: localizations.investmentType,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: AssetType.stock,
                        child: Text(localizations.investmentStock),
                      ),
                      DropdownMenuItem(
                        value: AssetType.bond,
                        child: Text(localizations.investmentBond),
                      ),
                      DropdownMenuItem(
                        value: AssetType.crypto,
                        child: Text(localizations.investmentCrypto),
                      ),
                      DropdownMenuItem(
                        value: AssetType.other,
                        child: Text(localizations.investmentOther),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _assetType = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Asset Name/Symbol field
                  TextFormField(
                    controller: _assetNameController,
                    decoration: InputDecoration(
                      labelText: _assetType == AssetType.other
                          ? localizations.investmentName
                          : localizations.commoditySymbol,
                      hintText: _assetType == AssetType.stock
                          ? localizations.investmentTickerHintStock
                          : _assetType == AssetType.crypto
                              ? localizations.investmentTickerHintCrypto
                              : _assetType == AssetType.bond
                                  ? localizations.investmentTickerHintBond
                                  : localizations.investmentTickerHintOther,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    textCapitalization: _assetType == AssetType.other
                        ? TextCapitalization.words
                        : TextCapitalization.characters,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return localizations.requiredField;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Quantity field
                  TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: localizations.quantity,
                      hintText: localizations.investmentQuantityHint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return localizations.investmentEnterQuantity;
                      }
                      final num = double.tryParse(value);
                      if (num == null || num <= 0) {
                        return localizations.investmentGreaterThanZero;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Purchase Value field
                  TextFormField(
                    controller: _purchaseValueController,
                    decoration: InputDecoration(
                      labelText: localizations.investmentTotalPaid,
                      hintText: localizations.investmentHowMuch,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return localizations.investmentEnterAmount;
                      }
                      final num = double.tryParse(value);
                      if (num == null || num <= 0) {
                        return localizations.investmentGreaterThanZero;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Currency Dropdown
                  DropdownButtonFormField<Currency>(
                    initialValue: _currency,
                    decoration: InputDecoration(
                      labelText: localizations.investmentCurrencyLabel,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: Currency.vnd,
                        child: Text('VND (₫)'),
                      ),
                      DropdownMenuItem(
                        value: Currency.usd,
                        child: Text('USD (\$)'),
                      ),
                      DropdownMenuItem(
                        value: Currency.eur,
                        child: Text('EUR (€)'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _currency = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Purchase Date field
                  InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: localizations.investmentPurchaseDate,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_purchaseDate.day}/${_purchaseDate.month}/${_purchaseDate.year}',
                            style: TextStyle(fontSize: 16),
                          ),
                          Icon(Icons.calendar_today, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(localizations.cancel),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(localizations.save),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
