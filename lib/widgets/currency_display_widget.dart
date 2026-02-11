import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/currency_service.dart';

/// Example widget demonstrating currency conversion and formatting
/// This can be used as a reference for implementing currency display in your app
class CurrencyDisplayWidget extends StatefulWidget {
  final double amount;
  final String? sourceCurrency;
  final TextStyle? textStyle;
  final bool showSourceCurrency;
  
  const CurrencyDisplayWidget({
    super.key,
    required this.amount,
    this.sourceCurrency,
    this.textStyle,
    this.showSourceCurrency = false,
  });

  @override
  State<CurrencyDisplayWidget> createState() => _CurrencyDisplayWidgetState();
}

class _CurrencyDisplayWidgetState extends State<CurrencyDisplayWidget> {
  final CurrencyService _currencyService = CurrencyService();
  double? _convertedAmount;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _convertCurrency();
  }

  @override
  void didUpdateWidget(CurrencyDisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amount != widget.amount || 
        oldWidget.sourceCurrency != widget.sourceCurrency) {
      _convertCurrency();
    }
  }

  Future<void> _convertCurrency() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final targetCurrency = settings.currency.code;
    final sourceCurrency = widget.sourceCurrency ?? targetCurrency;

    if (sourceCurrency == targetCurrency) {
      setState(() {
        _convertedAmount = widget.amount;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final converted = await _currencyService.convert(
        amount: widget.amount,
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
          _error = 'Conversion failed';
          _convertedAmount = widget.amount;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        if (_isLoading) {
          return const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        final displayAmount = _convertedAmount ?? widget.amount;
        final formatted = _currencyService.formatCurrency(
          amount: displayAmount,
          currencyCode: settings.currency.code,
          symbol: settings.currency.symbol,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatted,
              style: widget.textStyle,
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.showSourceCurrency && 
                widget.sourceCurrency != null && 
                widget.sourceCurrency != settings.currency.code)
              Text(
                '(Original: ${_currencyService.formatCurrency(
                  amount: widget.amount,
                  currencyCode: widget.sourceCurrency!,
                  symbol: AppCurrency.fromCode(widget.sourceCurrency!).symbol,
                )})',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            if (_error != null)
              Text(
                _error!,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.orange,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Simple synchronous currency display without conversion
class SimpleCurrencyDisplay extends StatelessWidget {
  final double amount;
  final TextStyle? textStyle;
  
  const SimpleCurrencyDisplay({
    super.key,
    required this.amount,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final currencyService = CurrencyService();
        final formatted = currencyService.formatCurrency(
          amount: amount,
          currencyCode: settings.currency.code,
          symbol: settings.currency.symbol,
        );
        
        return Text(
          formatted,
          style: textStyle,
        );
      },
    );
  }
}
