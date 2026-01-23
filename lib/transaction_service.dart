import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class TransactionService {
  static const String _transactionsKey = 'transactions';
  static const String _baseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:8080',
  );
  
  // Short timeout for offline-first behavior
  static const Duration _apiTimeout = Duration(seconds: 3);

  Future<List<Map<String, dynamic>>> getTransactions() async {
    // Try to fetch from backend if available
    try {
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
    
    // Try to sync with backend if available
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
}

