import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import 'package:xml/xml.dart';
import 'services/backend_ffi_service.dart';

class TransactionService {
  static const String _transactionsKey = 'transactions';
  static const String _baseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:8080',
  );
  
  // Short timeout for offline-first behavior
  static const Duration _apiTimeout = Duration(seconds: 3);

  final BackendFfiService _ffiService = BackendFfiService();

  Future<List<Map<String, dynamic>>> getTransactions() async {
    // Try to fetch from backend FFI if available
    if (_ffiService.isAvailable) {
      try {
        final data = await _ffiService.getTransactions();
        // Cache the response locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_transactionsKey, json.encode(data));
        return data;
      } catch (e) {
        if (kDebugMode) {
          print('Backend FFI error: $e');
        }
      }
    }

    // Try to fetch from HTTP backend if FFI is unavailable
    try {
      // Check if we're on HTTPS trying to hit HTTP (will fail due to mixed content)
      if (kIsWeb && 
          Uri.base.scheme == 'https' && 
          _baseUrl.startsWith('http:')) {
        if (kDebugMode) {
          print('⚠️ Mixed content blocked: Cannot fetch HTTP backend from HTTPS frontend.');
        }
        throw Exception('Mixed content blocked');
      }

      final response = await http
          .get(Uri.parse('$_baseUrl/api/transactions'))
          .timeout(_apiTimeout);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Cache the response locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_transactionsKey, json.encode(data));
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      // Silently fall back to local storage - this is expected for offline-first
      if (kDebugMode) {
        print('Backend unavailable, using local data: $e');
      }
    }
    
    final prefs = await SharedPreferences.getInstance();
    final String? transactionsJson = prefs.getString(_transactionsKey);
    if (transactionsJson != null) {
      final List<dynamic> data = json.decode(transactionsJson);
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<void> importTransaction(Map<String, dynamic> transactionData) async {
    // Always save locally first for offline-first approach
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> transactions = await getTransactions();
    transactions.add(transactionData);
    await prefs.setString(_transactionsKey, json.encode(transactions));
    
    // Try to sync with backend FFI if available
    if (_ffiService.isAvailable) {
      try {
        await _ffiService.saveTransaction(transactionData);
        if (kDebugMode) {
          print('Transaction synced with backend FFI successfully');
        }
        return;
      } catch (e) {
        if (kDebugMode) {
          print('Backend FFI unavailable or error: $e');
        }
      }
    }

    // Try to sync with HTTP backend if FFI is unavailable
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/transactions'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(transactionData),
      ).timeout(_apiTimeout);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          print('Transaction synced with backend successfully');
        }
      }
    } catch (e) {
      // Backend unavailable - data is already saved locally
      if (kDebugMode) {
        print('Backend unavailable, transaction saved locally only: $e');
      }
    }
  }

  Future<Map<String, dynamic>> parseJsonFile(String jsonContent) async {
    final Map<String, dynamic> data = json.decode(jsonContent);
    
    final List<Map<String, dynamic>> transactions = [];
    
    if (data.containsKey('income') && data['income']['accounts'] != null) {
      final accounts = data['income']['accounts'] as Map<String, dynamic>;
      accounts.forEach((account, amounts) {
        amounts.forEach((currency, amount) {
          transactions.add({
            'type': 'income',
            'account': account,
            'currency': currency,
            'amount': amount,
            'date': DateTime.now().toIso8601String(),
          });
        });
      });
    }
    
    if (data.containsKey('expense') && data['expense']['accounts'] != null) {
      final accounts = data['expense']['accounts'] as Map<String, dynamic>;
      accounts.forEach((account, amounts) {
        amounts.forEach((currency, amount) {
          transactions.add({
            'type': 'expense',
            'account': account,
            'currency': currency,
            'amount': amount,
            'date': DateTime.now().toIso8601String(),
          });
        });
      });
    }
    
    return {
      'transactions': transactions,
      'tally': data['tally'] ?? {},
    };
  }

  Future<List<Map<String, dynamic>>> parseCsvFile(String csvContent) async {
    // Simple CSV parser assuming headers: Date, Payee, Amount, Currency, Category, Description
    List<List<dynamic>> rows = const CsvToListConverter().convert(csvContent);
    
    if (rows.isEmpty) return [];

    // Basic heuristic: check if first row is header
    List<String> headers = rows[0].map((e) => e.toString().toLowerCase()).toList();
    bool hasHeader = headers.contains('date') || headers.contains('amount');
    
    int startRow = hasHeader ? 1 : 0;
    List<Map<String, dynamic>> transactions = [];
    
    // Map column indices if header exists
    Map<String, int> colMap = {};
    if (hasHeader) {
      for (int i = 0; i < headers.length; i++) {
        colMap[headers[i]] = i;
      }
    }

    for (int i = startRow; i < rows.length; i++) {
      var row = rows[i];
      if (row.isEmpty) continue;
      
      // Helper to safely get value by index or column name
      dynamic getValue(String key, int defaultIndex) {
        if (hasHeader && colMap.containsKey(key)) {
          int idx = colMap[key]!;
          if (idx < row.length) return row[idx];
        } else if (!hasHeader && defaultIndex < row.length) {
          return row[defaultIndex];
        }
        return null;
      }

      String date = getValue('date', 0)?.toString() ?? DateTime.now().toIso8601String();
      String payee = getValue('payee', 1)?.toString() ?? '';
      double amount = double.tryParse(getValue('amount', 2)?.toString().replaceAll(',', '') ?? '0') ?? 0.0;
      String currency = getValue('currency', 3)?.toString() ?? 'VND';
      String category = getValue('category', 4)?.toString() ?? '';
      String description = getValue('description', 5)?.toString() ?? '';

      transactions.add({
        'date': date,
        'payee': payee,
        'amount': amount,
        'currency': currency,
        'category': category,
        'description': description,
        'type': amount < 0 ? 'expense' : 'income', // Simple heuristic
      });
    }

    return transactions;
  }

  Future<List<Map<String, dynamic>>> parseXmlFile(String xmlContent) async {
    final document = XmlDocument.parse(xmlContent);
    final transactions = <Map<String, dynamic>>[];

    // Look for common transaction tags like <Transaction>, <Entry>, etc.
    final elements = document.findAllElements('Transaction'); // Adjust based on expected XML format
    
    for (var element in elements) {
      String getValue(String tag) {
        return element.findElements(tag).firstOrNull?.innerText ?? '';
      }

      String date = getValue('Date');
      if (date.isEmpty) date = DateTime.now().toIso8601String();
      
      String payee = getValue('Payee');
      String amountStr = getValue('Amount');
      double amount = double.tryParse(amountStr.replaceAll(',', '')) ?? 0.0;
      String currency = getValue('Currency');
      if (currency.isEmpty) currency = 'VND';
      
      transactions.add({
        'date': date,
        'payee': payee,
        'amount': amount,
        'currency': currency,
        'description': getValue('Description'),
        'category': getValue('Category'),
        'type': amount < 0 ? 'expense' : 'income',
      });
    }
    
    // If no specific Transaction tags, maybe try generic scan or different schema
    if (transactions.isEmpty) {
        // Fallback or generic parsing logic could go here
    }

    return transactions;
  }
}

