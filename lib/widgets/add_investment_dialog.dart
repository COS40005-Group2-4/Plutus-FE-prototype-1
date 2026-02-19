import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'glass_container.dart';
import '../l10n/app_localizations.dart';
import '../models/investment_model.dart';

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
          color: isDark ? const Color(0xFF1A3A4A) : Colors.white,
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
                    value: _assetType,
                    decoration: InputDecoration(
                      labelText: 'Asset Type *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: AssetType.stock,
                        child: Text('Stock'),
                      ),
                      DropdownMenuItem(
                        value: AssetType.bond,
                        child: Text('Bond'),
                      ),
                      DropdownMenuItem(
                        value: AssetType.crypto,
                        child: Text('Cryptocurrency'),
                      ),
                      DropdownMenuItem(
                        value: AssetType.other,
                        child: Text('Other'),
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
                          ? 'Asset Name *'
                          : 'Symbol/Ticker *',
                      hintText: _assetType == AssetType.stock
                          ? 'e.g., AAPL, GOOGL'
                          : _assetType == AssetType.crypto
                              ? 'e.g., BTC, ETH'
                              : _assetType == AssetType.bond
                                  ? 'e.g., US10Y'
                                  : 'e.g., Gold, Real Estate',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    textCapitalization: _assetType == AssetType.other
                        ? TextCapitalization.words
                        : TextCapitalization.characters,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'This field is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Quantity field
                  TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: 'Quantity *',
                      hintText: 'e.g., 10, 0.5',
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
                        return 'Quantity is required';
                      }
                      final num = double.tryParse(value);
                      if (num == null || num <= 0) {
                        return 'Must be a positive number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Purchase Value field
                  TextFormField(
                    controller: _purchaseValueController,
                    decoration: InputDecoration(
                      labelText: 'Total Purchase Value *',
                      hintText: 'Total amount paid',
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
                        return 'Purchase value is required';
                      }
                      final num = double.tryParse(value);
                      if (num == null || num <= 0) {
                        return 'Must be a positive number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Currency Dropdown
                  DropdownButtonFormField<Currency>(
                    value: _currency,
                    decoration: InputDecoration(
                      labelText: 'Currency *',
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
                        labelText: 'Purchase Date *',
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
                          backgroundColor: const Color(0xFF4A90E2),
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
