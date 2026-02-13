import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class CurrencyService {
  // Exchange rates relative to VND (Vietnamese Dong)
  // These are approximate rates - in production, you'd fetch from an API
  static const Map<String, double> _exchangeRates = {
    'VND': 1.0,
    'USD': 25000.0,  // 1 USD ≈ 25,000 VND
    'EUR': 27000.0,  // 1 EUR ≈ 27,000 VND
    'GBP': 31000.0,  // 1 GBP ≈ 31,000 VND
    'JPY': 170.0,    // 1 JPY ≈ 170 VND
    'CNY': 3500.0,   // 1 CNY ≈ 3,500 VND
  };

  /// Convert amount from source currency to VND
  static double toVND(double amount, String fromCurrency) {
    final rate = _exchangeRates[fromCurrency.toUpperCase()] ?? 1.0;
    return amount * rate;
  }

  /// Convert amount from VND to target currency
  static double fromVND(double amountInVND, String toCurrency) {
    final rate = _exchangeRates[toCurrency.toUpperCase()] ?? 1.0;
    return amountInVND / rate;
  }

  /// Convert amount from one currency to another (async for compatibility)
  Future<double> convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    if (fromCurrency.toUpperCase() == toCurrency.toUpperCase()) {
      return amount;
    }
    
    // Convert to VND first, then to target currency
    final amountInVND = toVND(amount, fromCurrency);
    return fromVND(amountInVND, toCurrency);
  }

  /// Get exchange rate between two currencies
  static double getExchangeRate(String fromCurrency, String toCurrency) {
    if (fromCurrency.toUpperCase() == toCurrency.toUpperCase()) {
      return 1.0;
    }
    
    final fromRate = _exchangeRates[fromCurrency.toUpperCase()] ?? 1.0;
    final toRate = _exchangeRates[toCurrency.toUpperCase()] ?? 1.0;
    
    return fromRate / toRate;
  }

  /// Check if currency is supported
  static bool isSupported(String currency) {
    return _exchangeRates.containsKey(currency.toUpperCase());
  }

  /// Get currency symbol
  static String getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'VND':
        return '₫';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'CNY':
        return '¥';
      default:
        return currency;
    }
  }

  /// Format amount with currency (named parameters for compatibility)
  String formatCurrency({
    required double amount,
    required String currencyCode,
    bool showSymbol = true,
  }) {
    final symbol = getCurrencySymbol(currencyCode);
    
    if (currencyCode.toUpperCase() == 'VND') {
      // VND doesn't use decimals
      final formatter = NumberFormat('#,##0', 'vi_VN');
      return showSymbol ? '${formatter.format(amount)} $symbol' : formatter.format(amount);
    } else {
      // Other currencies use 2 decimal places
      final formatter = NumberFormat('#,##0.00', 'en_US');
      if (showSymbol) {
        return '$symbol${formatter.format(amount)}';
      } else {
        return formatter.format(amount);
      }
    }
  }

  /// Format amount with currency (positional parameters - legacy support)
  static String formatAmount(double amount, String currency) {
    final symbol = getCurrencySymbol(currency);
    
    if (currency.toUpperCase() == 'VND') {
      // VND doesn't use decimals
      final formatter = NumberFormat('#,##0', 'vi_VN');
      return '${formatter.format(amount)} $symbol';
    } else {
      // Other currencies use 2 decimal places
      final formatter = NumberFormat('#,##0.00', 'en_US');
      return '$symbol${formatter.format(amount)}';
    }
  }
}
