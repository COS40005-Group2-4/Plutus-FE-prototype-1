import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class TransactionService {
  static const String _transactionsKey = 'transactions';
  static const String _baseUrl = 'http://localhost:8080';

  Future<List<Map<String, dynamic>>> getTransactions() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/transactions'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      // Fallback to local storage if API is not available
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
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/transactions'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(transactionData),
      );
      if (response.statusCode == 200) {
        return;
      }
    } catch (e) {
      // Fallback to local storage if API is not available
    }
    
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> transactions = await getTransactions();
    transactions.add(transactionData);
    await prefs.setString(_transactionsKey, json.encode(transactions));
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

