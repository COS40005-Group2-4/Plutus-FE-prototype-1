import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CurrencyService {
  static const String _cacheKey = 'exchange_rates';
  static const String _cacheTimestampKey = 'exchange_rates_timestamp';
  static const Duration _cacheValidDuration = Duration(hours: 12);

  Map<String, double>? _cachedRates;
  DateTime? _cacheTimestamp;

  // Get API key from environment
  String? get _apiKey => dotenv.env['EXCHANGE_RATE_API_KEY'];

  Future<Map<String, double>> getExchangeRates({bool forceRefresh = false}) async {
    // Check if cached rates are still valid
    if (!forceRefresh && _cachedRates != null && _cacheTimestamp != null) {
      if (DateTime.now().difference(_cacheTimestamp!) < _cacheValidDuration) {
        return _cachedRates!;
      }
    }

    // Try to load from SharedPreferences first
    if (!forceRefresh) {
      final cachedData = await _loadFromCache();
      if (cachedData != null) {
        _cachedRates = cachedData;
        return cachedData;
      }
    }

    // Fetch from API
    try {
      final rates = await _fetchFromApi();
      await _saveToCache(rates);
      _cachedRates = rates;
      _cacheTimestamp = DateTime.now();
      return rates;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching exchange rates: $e');
      }
      // Return cached data if available, even if expired
      if (_cachedRates != null) {
        return _cachedRates!;
      }
      // Return default rates as fallback
      return _getDefaultRates();
    }
  }

  Future<Map<String, double>> _fetchFromApi() async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      if (kDebugMode) {
        print('Warning: EXCHANGE_RATE_API_KEY not found in .env file. Using default rates.');
      }
      return _getDefaultRates();
    }

    final url = 'https://v6.exchangerate-api.com/v6/$_apiKey/latest/VND';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] == 'success') {
        final conversionRates = data['conversion_rates'] as Map<String, dynamic>;
        final rates = <String, double>{};
        conversionRates.forEach((key, value) {
          rates[key] = (value is int) ? value.toDouble() : (value as num).toDouble();
        });
        return rates;
      } else {
        throw Exception('API returned error: ${data['error-type']}');
      }
    } else {
      throw Exception('Failed to fetch exchange rates: ${response.statusCode}');
    }
  }

  Future<Map<String, double>?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);
      final timestampStr = prefs.getString(_cacheTimestampKey);

      if (cachedJson != null && timestampStr != null) {
        final timestamp = DateTime.parse(timestampStr);
        if (DateTime.now().difference(timestamp) < _cacheValidDuration) {
          _cacheTimestamp = timestamp;
          final cachedData = json.decode(cachedJson) as Map<String, dynamic>;
          final rates = <String, double>{};
          cachedData.forEach((key, value) {
            rates[key] = (value is int) ? value.toDouble() : (value as num).toDouble();
          });
          return rates;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading cached rates: $e');
      }
    }
    return null;
  }

  Future<void> _saveToCache(Map<String, double> rates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, json.encode(rates));
      await prefs.setString(_cacheTimestampKey, DateTime.now().toIso8601String());
    } catch (e) {
      if (kDebugMode) {
        print('Error saving rates to cache: $e');
      }
    }
  }

  Map<String, double> _getDefaultRates() {
    // Fallback rates (approximate as of 2024)
    // 1 VND = X of other currency
    return {
      'VND': 1.0,
      'USD': 0.000041, // ~1 USD = 24,000 VND
      'EUR': 0.000037, // ~1 EUR = 27,000 VND
      'JPY': 0.0056,
      'GBP': 0.000032,
    };
  }

  Future<double> convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    // Normalize currency codes
    final from = fromCurrency.trim().toUpperCase();
    final to = toCurrency.trim().toUpperCase();
    
    // Handle empty or invalid inputs
    if (from.isEmpty || to.isEmpty) {
      if (kDebugMode) {
        print('Warning: Empty currency code in conversion');
      }
      return amount;
    }
    
    // No conversion needed if same currency
    if (from == to) {
      return amount;
    }

    try {
      final rates = await getExchangeRates();

      // All rates are based on VND, so we need to convert accordingly
      // If from VND to other currency
      if (from == 'VND') {
        final rate = rates[to];
        if (rate != null && rate > 0) {
          return amount * rate;
        }
      }
      // If from other currency to VND
      else if (to == 'VND') {
        final rate = rates[from];
        if (rate != null && rate > 0) {
          return amount / rate;
        }
      }
      // If between two non-VND currencies
      else {
        final fromRate = rates[from];
        final toRate = rates[to];
        if (fromRate != null && toRate != null && fromRate > 0 && toRate > 0) {
          // Convert to VND first, then to target currency
          final inVnd = amount / fromRate;
          return inVnd * toRate;
        }
      }
      
      if (kDebugMode) {
        print('Warning: Could not find exchange rate for $from to $to');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error converting currency: $e');
      }
    }

    return amount; // Return original amount if conversion fails
  }

  String formatCurrency({
    required double amount,
    required String currencyCode,
    String? symbol,
    int decimalPlaces = 2,
  }) {
    final code = currencyCode.trim().toUpperCase();
    
    if (code == 'VND') {
      // VND doesn't use decimal places - show full number
      final roundedAmount = amount.round();
      final formattedNumber = roundedAmount.abs().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
      return '${symbol ?? '₫'}$formattedNumber';
    } else {
      // Other currencies use 2 decimal places
      final absAmount = amount.abs();
      final formattedAmount = absAmount.toStringAsFixed(decimalPlaces);
      final parts = formattedAmount.split('.');
      final integerPart = parts[0].replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
      return '${symbol ?? code}$integerPart.${parts[1]}';
    }
  }
}
