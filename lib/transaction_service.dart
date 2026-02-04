import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import 'package:xml/xml.dart';
import 'services/backend_ffi_service.dart';
import 'services/database_service.dart';
import 'models/transaction_model.dart';

class TransactionService {
  static const String _transactionsKey = 'transactions';
  static const String _baseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:8080',
  );
  
  // Short timeout for offline-first behavior
  static const Duration _apiTimeout = Duration(seconds: 3);

  final BackendFfiService _ffiService = BackendFfiService();
  final DatabaseService _db = DatabaseService();
  
  int? _currentUserId;
  
  void setCurrentUser(int userId) {
    _currentUserId = userId;
  }
  
  // Helper to flatten transaction with postings into flat structure for database
  Map<String, dynamic> _flattenTransaction(Map<String, dynamic> tx) {
    // Extract date
    String dateStr;
    if (tx['date'] is int) {
      dateStr = DateTime.fromMillisecondsSinceEpoch((tx['date'] as int) * 1000).toIso8601String();
    } else if (tx['date'] is String) {
      dateStr = tx['date'] as String;
    } else {
      dateStr = DateTime.now().toIso8601String();
    }
    
    // Extract postings if available
    String account = 'Assets:Cash';
    String category = 'Expenses:Other';
    double amount = 0.0;
    String currency = 'VND';
    String type = 'expense';
    
    if (tx['postings'] != null && tx['postings'] is List && (tx['postings'] as List).isNotEmpty) {
      final postings = tx['postings'] as List;
      final firstPosting = postings[0] as Map<String, dynamic>;
      final secondPosting = postings.length > 1 ? postings[1] as Map<String, dynamic> : null;
      
      account = firstPosting['account'] as String? ?? account;
      currency = firstPosting['commodity'] as String? ?? currency;
      final firstAmount = (firstPosting['amount'] as num?)?.toDouble() ?? 0.0;
      
      if (secondPosting != null) {
        category = secondPosting['account'] as String? ?? category;
        amount = (secondPosting['amount'] as num?)?.toDouble().abs() ?? firstAmount.abs();
      } else {
        amount = firstAmount.abs();
      }
      
      // Determine type based on first posting amount
      type = firstAmount < 0 ? 'expense' : 'income';
    } else if (tx['amount'] != null) {
      // Already flat structure
      amount = (tx['amount'] as num?)?.toDouble().abs() ?? 0.0;
      account = tx['account'] as String? ?? account;
      category = tx['category'] as String? ?? category;
      currency = tx['currency'] as String? ?? currency;
      type = tx['type'] as String? ?? type;
    }
    
    return {
      'transaction_id': tx['id'] ?? 'tx_${DateTime.now().millisecondsSinceEpoch}',
      'type': type,
      'amount': amount,
      'currency': currency,
      'category': category,
      'description': tx['description'] as String? ?? '',
      'payee': tx['payee'] as String? ?? '',
      'date': dateStr,
      'account': account,
    };
  }

  Future<List<Transaction>> getTransactions() async {
    if (_currentUserId == null) {
      if (kDebugMode) {
        print('No user logged in, returning empty transactions');
      }
      return [];
    }
    
    // OFFLINE-FIRST: Always load from local database first
    final localTransactions = await _getLocalTransactions(_currentUserId!);
    
    // Try to sync with backend FFI in the background
    _syncWithBackend(_currentUserId!);
    
    return localTransactions;
  }
  
  Future<List<Transaction>> _getLocalTransactions(int userId) async {
    try {
      final txMaps = await _db.getTransactionsByUserId(userId);
      if (kDebugMode) {
        print('Retrieved ${txMaps.length} transactions from database for user $userId');
      }
      
      return txMaps.map((map) {
        // Convert flat database structure to Transaction model format
        final dateStr = map['date'] as String? ?? DateTime.now().toIso8601String();
        final dateTime = DateTime.tryParse(dateStr) ?? DateTime.now();
        final dateUnix = dateTime.millisecondsSinceEpoch ~/ 1000;
        
        final amount = (map['amount'] as num?)?.toDouble() ?? 0.0;
        final currency = map['currency'] as String? ?? 'VND';
        final account = map['account'] as String? ?? 'Assets:Cash';
        final category = map['category'] as String? ?? 'Expenses:Other';
        final type = map['type'] as String? ?? 'expense';
        
        // Create postings array from flat structure
        final postings = <Map<String, dynamic>>[];
        
        if (type == 'expense') {
          // Expense: money goes out of account (negative) and into expense category (positive)
          postings.add({
            'account': account,
            'amount': -amount.abs(),
            'commodity': currency,
          });
          postings.add({
            'account': category,
            'amount': amount.abs(),
            'commodity': currency,
          });
        } else {
          // Income: money goes into account (positive) and from income source (negative)
          postings.add({
            'account': account,
            'amount': amount.abs(),
            'commodity': currency,
          });
          postings.add({
            'account': category,
            'amount': -amount.abs(),
            'commodity': currency,
          });
        }
        
        return Transaction.fromJson({
          'date': dateUnix,
          'payee': map['payee'] as String? ?? '',
          'description': map['description'] as String? ?? '',
          'postings': postings,
        });
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading local transactions: $e');
      }
      return [];
    }
  }
  
  Future<void> _syncWithBackend(int userId) async {
    // Try to fetch from backend FFI if available
    if (_ffiService.isAvailable) {
      try {
        final data = await _ffiService.getTransactions();
        
        if (kDebugMode) {
          print('Fetched ${data.length} transactions from FFI backend');
        }
        
        // Store FFI transactions in local database
        // FFI returns transactions with postings, need to flatten for database
        for (final tx in data) {
          final flatTx = _flattenTransaction(tx);
          try {
            await _db.insertTransaction(userId, flatTx);
          } catch (e) {
            if (kDebugMode) {
              print('Error inserting transaction: $e');
            }
          }
        }
        
        // Also cache in SharedPreferences for backwards compatibility
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_transactionsKey, json.encode(data));
        
        if (kDebugMode) {
          print('Synced ${data.length} transactions from FFI backend to database');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Backend FFI sync error: $e');
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
        return;
      }

      final response = await http
          .get(Uri.parse('$_baseUrl/api/transactions'))
          .timeout(_apiTimeout);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        // Store HTTP transactions in local database
        for (final tx in data) {
          await _db.insertTransaction(userId, tx as Map<String, dynamic>);
        }
        
        // Cache in SharedPreferences for backwards compatibility
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_transactionsKey, json.encode(data));
        
        if (kDebugMode) {
          print('Synced ${data.length} transactions from HTTP backend');
        }
      }
    } catch (e) {
      // Silently fail - we're offline-first, so local data is fine
      if (kDebugMode) {
        print('Backend unavailable, using local data: $e');
      }
    }
  }

  Future<void> importTransactionFile(String filePath) async {
    // Call the FFI Import function to import the transaction file
    if (kDebugMode) {
      print('FFI Service Available: ${_ffiService.isAvailable}');
    }
    
    if (_ffiService.isAvailable) {
      try {
        if (kDebugMode) {
          print('Attempting to import file via FFI: $filePath');
        }
        await _ffiService.importFile(filePath);
        
        // After FFI import, sync the transactions to local database
        if (_currentUserId != null) {
          if (kDebugMode) {
            print('Syncing transactions to local database for user $_currentUserId');
          }
          await _syncWithBackend(_currentUserId!);
        }
        
        if (kDebugMode) {
          print('Transaction file imported successfully via FFI');
        }
        return;
      } catch (e) {
        if (kDebugMode) {
          print('Backend FFI import error: $e');
        }
        rethrow;
      }
    } else {
      // Fallback: Parse the file manually and save to local database
      if (kDebugMode) {
        print('Backend FFI not available, attempting manual file parsing');
      }
      
      if (_currentUserId == null) {
        throw Exception('No user logged in');
      }
      
      try {
        final file = File(filePath);
        if (!await file.exists()) {
          throw Exception('File not found: $filePath');
        }
        
        final extension = filePath.split('.').last.toLowerCase();
        final content = await file.readAsString();
        
        List<Map<String, dynamic>> transactions = [];
        
        if (extension == 'json') {
          final parsed = await parseJsonFile(content);
          transactions = parsed['transactions'] as List<Map<String, dynamic>>? ?? [];
        } else if (extension == 'csv') {
          transactions = await parseCsvFile(content);
        } else if (extension == 'xml') {
          transactions = await parseXmlFile(content);
        } else {
          throw Exception('Unsupported file format: $extension');
        }
        
        // Import each transaction to local database
        for (final tx in transactions) {
          await _db.insertTransaction(_currentUserId!, tx);
        }
        
        if (kDebugMode) {
          print('Imported ${transactions.length} transactions from $extension file');
        }
        
        return;
      } catch (e) {
        if (kDebugMode) {
          print('Manual file import error: $e');
        }
        rethrow;
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
            'amount': -amount.abs(),
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
        'type': amount < 0 ? 'expense' : 'income', 
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

  Future<void> importTransaction(Map<String, dynamic> transaction) async {
    if (_currentUserId == null) {
      throw Exception('No user logged in');
    }
    
    try {
      // OFFLINE-FIRST: Save to local database first
      await _db.insertTransaction(_currentUserId!, transaction);
      
      // Also save to SharedPreferences for backwards compatibility
      final prefs = await SharedPreferences.getInstance();
      final String? transactionsJson = prefs.getString(_transactionsKey);
      final List<dynamic> transactions = transactionsJson != null ? json.decode(transactionsJson) : [];
      transactions.add(transaction);
      await prefs.setString(_transactionsKey, json.encode(transactions));
      
      if (kDebugMode) {
        print('Transaction imported successfully: $transaction');
      }
      
      // Try to sync with backend in the background (non-blocking)
      _syncTransactionToBackend(transaction);
    } catch (e) {
      if (kDebugMode) {
        print('Error importing transaction: $e');
      }
      rethrow;
    }
  }
  
  Future<void> _syncTransactionToBackend(Map<String, dynamic> transaction) async {
    // Try to sync with FFI backend
    if (_ffiService.isAvailable) {
      try {
        await _ffiService.saveTransaction(transaction);
        if (kDebugMode) {
          print('Transaction synced to FFI backend');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Failed to sync transaction to FFI backend: $e');
        }
      }
    }
  }
  
  Future<List<Map<String, dynamic>>> getUnsyncedTransactions() async {
    if (_currentUserId == null) return [];
    
    try {
      return await _db.getUnsyncedTransactions(_currentUserId!);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting unsynced transactions: $e');
      }
      return [];
    }
  }
  
  Future<void> syncPendingTransactions() async {
    if (_currentUserId == null) return;
    
    final unsynced = await getUnsyncedTransactions();
    
    for (final tx in unsynced) {
      try {
        if (_ffiService.isAvailable) {
          await _ffiService.saveTransaction(tx);
          await _db.markTransactionAsSynced(tx['id'] as int);
          if (kDebugMode) {
            print('Synced transaction ${tx['id']}');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Failed to sync transaction ${tx['id']}: $e');
        }
      }
    }
  }
}

