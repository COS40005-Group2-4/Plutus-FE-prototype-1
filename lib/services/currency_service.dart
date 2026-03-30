import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

class CurrencyService {
  // Fallback rates relative to VND (used when API is unavailable)
  static const Map<String, double> _fallbackRates = {
    'VND': 1.0,
    'USD': 25000.0,
    'EUR': 27000.0,
    'GBP': 31000.0,
    'JPY': 170.0,
    'CNY': 3500.0,
  };

  // Cached API rates: base currency -> { target -> rate }
  static final Map<String, Map<String, double>> _cachedRates = {};
  static DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(hours: 1);

  static String? get _apiKey => dotenv.env['EXCHANGE_RATE_API_KEY'];

  /// Fetch rates from ExchangeRate-API for a base currency
  static Future<Map<String, double>?> _fetchRates(String baseCurrency) async {
    final key = _apiKey;
    if (key == null || key.isEmpty) return null;

    try {
      final url = 'https://v6.exchangerate-api.com/v6/$key/latest/${baseCurrency.toUpperCase()}';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] == 'success') {
          final rates = (data['conversion_rates'] as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, (v as num).toDouble()));
          return rates;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CurrencyService: API fetch failed: $e');
      }
    }
    return null;
  }

  /// Get rates for a base currency (cached)
  static Future<Map<String, double>> _getRates(String baseCurrency) async {
    final base = baseCurrency.toUpperCase();

    // Check cache
    if (_cachedRates.containsKey(base) &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cachedRates[base]!;
    }

    // Try API
    final apiRates = await _fetchRates(base);
    if (apiRates != null) {
      _cachedRates[base] = apiRates;
      _cacheTime = DateTime.now();
      return apiRates;
    }

    // Fallback to hardcoded rates
    return _buildFallbackRates(base);
  }

  /// Build fallback conversion map from hardcoded VND-based rates
  static Map<String, double> _buildFallbackRates(String baseCurrency) {
    final base = baseCurrency.toUpperCase();
    final baseToVnd = _fallbackRates[base] ?? 1.0;
    final result = <String, double>{};
    for (final entry in _fallbackRates.entries) {
      result[entry.key] = entry.value / baseToVnd;
    }
    return result;
  }

  /// Convert amount from one currency to another
  Future<double> convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    if (fromCurrency.toUpperCase() == toCurrency.toUpperCase()) {
      return amount;
    }

    final rates = await _getRates(fromCurrency.toUpperCase());
    final rate = rates[toCurrency.toUpperCase()];
    if (rate != null) {
      return amount * rate;
    }

    // Fallback: go through VND
    final fromRate = _fallbackRates[fromCurrency.toUpperCase()] ?? 1.0;
    final toRate = _fallbackRates[toCurrency.toUpperCase()] ?? 1.0;
    return amount * fromRate / toRate;
  }

  /// Convert amount from source currency to VND
  static double toVND(double amount, String fromCurrency) {
    final rate = _fallbackRates[fromCurrency.toUpperCase()] ?? 1.0;
    return amount * rate;
  }

  /// Convert amount from VND to target currency
  static double fromVND(double amountInVND, String toCurrency) {
    final rate = _fallbackRates[toCurrency.toUpperCase()] ?? 1.0;
    return amountInVND / rate;
  }

  /// Get exchange rate between two currencies
  static double getExchangeRate(String fromCurrency, String toCurrency) {
    if (fromCurrency.toUpperCase() == toCurrency.toUpperCase()) {
      return 1.0;
    }
    final fromRate = _fallbackRates[fromCurrency.toUpperCase()] ?? 1.0;
    final toRate = _fallbackRates[toCurrency.toUpperCase()] ?? 1.0;
    return fromRate / toRate;
  }

  /// Check if currency is supported
  static bool isSupported(String currency) {
    return _fallbackRates.containsKey(currency.toUpperCase());
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
      case 'ORIGINAL':
        return '\$';
      default:
        return currency;
    }
  }

  /// Format amount with currency (named parameters)
  String formatCurrency({
    required double amount,
    required String currencyCode,
    bool showSymbol = true,
  }) {
    final symbol = getCurrencySymbol(currencyCode);

    if (currencyCode.toUpperCase() == 'VND') {
      final formatter = NumberFormat('#,##0', 'vi_VN');
      return showSymbol ? '${formatter.format(amount)} $symbol' : formatter.format(amount);
    } else {
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
      final formatter = NumberFormat('#,##0', 'vi_VN');
      return '${formatter.format(amount)} $symbol';
    } else {
      final formatter = NumberFormat('#,##0.00', 'en_US');
      return '$symbol${formatter.format(amount)}';
    }
  }
}
