import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import 'package:xml/xml.dart';
import 'services/backend_ffi_service.dart';
import 'services/interfaces/i_backend_ffi_service.dart';
import 'services/interfaces/i_database_service.dart';
import 'services/interfaces/i_transaction_service.dart';
import 'services/file_handler.dart';
import 'models/transaction_model.dart';
import 'models/ai/correction.dart';
import 'services/interfaces/i_ai_service.dart';
import 'di/service_locator.dart';

class TransactionService implements ITransactionService {
  static const String _transactionsKey = 'transactions';
  static const String _baseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:8080',
  );

  // Short timeout for offline-first behavior
  static const Duration _apiTimeout = Duration(seconds: 3);

  final IBackendFfiService _ffiService;
  final IDatabaseService _db;
  final IAIService _aiService;

  int? _currentUserId;

  // Stream controller for transaction updates
  late StreamController<List<Transaction>> _transactionStreamController;
  List<Transaction> _lastTransactions = [];

  @override
  Stream<List<Transaction>> get transactionStream => _transactionStreamController.stream;

  TransactionService({
    IBackendFfiService? ffiService,
    IDatabaseService? db,
    IAIService? aiService,
  })  : _ffiService = ffiService ?? sl<IBackendFfiService>(),
        _db = db ?? sl<IDatabaseService>(),
        _aiService = aiService ?? sl<IAIService>() {
    _transactionStreamController = StreamController<List<Transaction>>.broadcast();
  }
  
  void setCurrentUser(int userId) {
    _currentUserId = userId;
  }
  
  void dispose() {
    // Don't dispose - this is a singleton
    // _transactionStreamController.close();
  }
  
  void notifyTransactionUpdate() async {
    if (_currentUserId != null) {
      if (kDebugMode) {
        print('TransactionService: Notifying transaction update for user $_currentUserId');
      }
      final transactions = await getTransactions();
      _lastTransactions = transactions;
      if (kDebugMode) {
        print('TransactionService: Loaded ${transactions.length} transactions');
      }
      if (!_transactionStreamController.isClosed) {
        _transactionStreamController.add(transactions);
        if (kDebugMode) {
          print('TransactionService: Sent ${transactions.length} transactions to stream');
        }
      }
    } else {
      if (kDebugMode) {
        print('TransactionService: Cannot notify - no current user set');
      }
    }
  }
  
  /// Get the last cached transactions without waiting for async
  List<Transaction> getLastCachedTransactions() => _lastTransactions;
  
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
        // Convert database structure to Transaction model format
        final dateStr = map['date'] as String? ?? DateTime.now().toIso8601String();
        final dateTime = DateTime.tryParse(dateStr) ?? DateTime.now();
        final dateUnix = dateTime.millisecondsSinceEpoch ~/ 1000;
        
        final dbId = map['id'] as int?;
        
        // Get postings if available (from joined data)
        List<Map<String, dynamic>> postings = [];
        
        if (map['postings'] != null && map['postings'] is List) {
          // Postings already loaded from database
          postings = (map['postings'] as List).map((p) => {
            'account': p['account'] as String,
            'amount': (p['amount'] as num).toDouble(),
            'commodity': p['commodity'] as String,
          }).toList();
        } else {
          // Fallback: construct postings from flat structure (backward compatibility)
          final amount = (map['amount'] as num?)?.toDouble() ?? 0.0;
          final currency = map['currency'] as String? ?? 'VND';
          final account = map['account'] as String? ?? 'Assets:Cash';
          final category = map['category'] as String? ?? 'Expenses:Other';
          final type = map['type'] as String? ?? 'expense';
          
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
        }
        
        return Transaction.fromJson({
          'id': dbId,
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
    if (_currentUserId == null) {
      throw Exception('No user logged in');
    }
    
    if (!await FileHandler.exists(filePath)) {
      throw Exception('File not found: $filePath');
    }
    
    final extension = filePath.split('.').last.toLowerCase();
    
    if (kDebugMode) {
      print('Importing file: $filePath (extension: $extension)');
      print('FFI Service Available: ${_ffiService.isAvailable}');
    }
    
    // Only use FFI for ledger/txt files (journal format)
    // CSV, JSON, XML should use manual parsing
    if (_ffiService.isAvailable && (extension == 'ledger' || extension == 'txt')) {
      try {
        if (kDebugMode) {
          print('Attempting to import ledger file via FFI: $filePath');
        }
        await _ffiService.importFile(filePath);
        
        // After FFI import, sync the transactions to local database
        if (kDebugMode) {
          print('Syncing transactions to local database for user $_currentUserId');
        }
        await _syncWithBackend(_currentUserId!);
        
        // Notify listeners of transaction update
        notifyTransactionUpdate();
        
        if (kDebugMode) {
          print('Transaction file imported successfully via FFI');
        }
        return;
      } catch (e) {
        if (kDebugMode) {
          print('Backend FFI import error: $e');
          print('Falling back to manual ledger parsing');
        }
        // Fall through to manual parsing
      }
    }
    
    // Manual parsing for CSV, JSON, XML or when FFI is not available
    if (kDebugMode) {
      print('Using manual file parsing for $extension file');
    }
    
    try {
      final content = await FileHandler.readAsString(filePath);
      
      List<Map<String, dynamic>> transactions = [];
      
      if (extension == 'json') {
        final parsed = await parseJsonFile(content);
        transactions = parsed['transactions'] as List<Map<String, dynamic>>? ?? [];
      } else if (extension == 'csv') {
        transactions = await parseCsvFile(content);
      } else if (extension == 'xml') {
        transactions = await parseXmlFile(content);
      } else if (extension == 'ledger' || extension == 'txt') {
        // Try to parse ledger format manually
        transactions = await parseLedgerFile(content);
      } else {
        throw Exception('Unsupported file format: $extension');
      }
      
      // Import each transaction to local database
      for (final tx in transactions) {
        await _db.insertTransaction(_currentUserId!, tx);
      }
      
      // Notify listeners of transaction update
      notifyTransactionUpdate();
      
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

  Future<Map<String, dynamic>> parseJsonFile(String jsonContent) async {
    final Map<String, dynamic> data = json.decode(jsonContent);
    
    final List<Map<String, dynamic>> transactions = [];
    
    // Check if data has a 'transactions' array directly (new format)
    if (data.containsKey('transactions') && data['transactions'] is List) {
      final txList = data['transactions'] as List;
      for (var tx in txList) {
        if (tx is Map<String, dynamic>) {
          // Ensure all required fields are present
          final txMap = Map<String, dynamic>.from(tx);
          
          // Determine type if not present
          if (!txMap.containsKey('type')) {
            final amount = (txMap['amount'] as num?)?.toDouble() ?? 0.0;
            txMap['type'] = amount < 0 ? 'expense' : 'income';
          }
          
          // Build account paths if not present
          if (!txMap.containsKey('account')) {
            txMap['account'] = 'Assets:Cash';
          }
          
          if (!txMap.containsKey('category')) {
            final type = txMap['type'] as String;
            final categoryName = tx['category'] as String? ?? (type == 'expense' ? 'Other' : 'General');
            txMap['category'] = type == 'expense' 
                ? 'Expenses:$categoryName'
                : 'Income:$categoryName';
          }
          
          // Create postings if not present
          if (!txMap.containsKey('postings') || txMap['postings'] == null) {
            final amount = (txMap['amount'] as num?)?.toDouble() ?? 0.0;
            final currency = txMap['currency'] as String? ?? 'VND';
            final type = txMap['type'] as String;
            final assetAccount = txMap['account'] as String;
            final categoryAccount = txMap['category'] as String;
            
            List<Map<String, dynamic>> postings = [];
            if (type == 'expense') {
              postings.add({
                'account': assetAccount,
                'amount': -amount.abs(),
                'commodity': currency,
              });
              postings.add({
                'account': categoryAccount,
                'amount': amount.abs(),
                'commodity': currency,
              });
            } else {
              postings.add({
                'account': assetAccount,
                'amount': amount.abs(),
                'commodity': currency,
              });
              postings.add({
                'account': categoryAccount,
                'amount': -amount.abs(),
                'commodity': currency,
              });
            }
            txMap['postings'] = postings;
          }
          
          transactions.add(txMap);
        }
      }
    }
    // Legacy format with income/expense accounts
    else {
      if (data.containsKey('income') && data['income']['accounts'] != null) {
        final accounts = data['income']['accounts'] as Map<String, dynamic>;
        accounts.forEach((account, amounts) {
          amounts.forEach((currency, amount) {
            final amountValue = (amount as num).toDouble();
            transactions.add({
              'type': 'income',
              'account': 'Assets:Cash',
              'category': 'Income:$account',
              'currency': currency,
              'amount': amountValue,
              'date': DateTime.now().toIso8601String(),
              'payee': account,
              'description': 'Income from $account',
              'postings': [
                {
                  'account': 'Assets:Cash',
                  'amount': amountValue.abs(),
                  'commodity': currency,
                },
                {
                  'account': 'Income:$account',
                  'amount': -amountValue.abs(),
                  'commodity': currency,
                },
              ],
            });
          });
        });
      }
      
      if (data.containsKey('expense') && data['expense']['accounts'] != null) {
        final accounts = data['expense']['accounts'] as Map<String, dynamic>;
        accounts.forEach((account, amounts) {
          amounts.forEach((currency, amount) {
            final amountValue = (amount as num).toDouble();
            transactions.add({
              'type': 'expense',
              'account': 'Assets:Cash',
              'category': 'Expenses:$account',
              'currency': currency,
              'amount': -amountValue.abs(),
              'date': DateTime.now().toIso8601String(),
              'payee': account,
              'description': 'Expense for $account',
              'postings': [
                {
                  'account': 'Assets:Cash',
                  'amount': -amountValue.abs(),
                  'commodity': currency,
                },
                {
                  'account': 'Expenses:$account',
                  'amount': amountValue.abs(),
                  'commodity': currency,
                },
              ],
            });
          });
        });
      }
    }
    
    return {
      'transactions': transactions,
      'tally': data['tally'] ?? {},
    };
  }

  Future<List<Map<String, dynamic>>> parseCsvFile(String csvContent) async {
    try {
      // Simple CSV parser assuming headers: Date, Payee, Amount, Currency, Category, Description
      List<List<dynamic>> rows = CsvDecoder().convert(csvContent);
      
      if (rows.isEmpty) return [];

      // Basic heuristic: check if first row is header
      List<String> headers = rows[0].map((e) => e.toString().toLowerCase().trim()).toList();
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
        try {
          var row = rows[i];
          if (row.isEmpty || row.every((cell) => cell.toString().trim().isEmpty)) continue;
          
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

          // Parse date with multiple format support
          String dateStr = getValue('date', 0)?.toString().trim() ?? '';
          String date;
          
          if (dateStr.isEmpty) {
            date = DateTime.now().toIso8601String();
          } else {
            try {
              // Try parsing various date formats
              DateTime parsedDate;
              
              // Try ISO format first (yyyy-MM-dd or yyyy-MM-ddTHH:mm:ss)
              if (dateStr.contains('T') || dateStr.contains('-')) {
                parsedDate = DateTime.parse(dateStr);
              }
              // Try dd/MM/yyyy format
              else if (dateStr.contains('/')) {
                final parts = dateStr.split('/');
                if (parts.length == 3) {
                  final day = int.parse(parts[0]);
                  final month = int.parse(parts[1]);
                  final year = int.parse(parts[2]);
                  parsedDate = DateTime(year, month, day);
                } else {
                  parsedDate = DateTime.now();
                }
              }
              // Try dd-MM-yyyy format
              else if (dateStr.split('-').length == 3 && !dateStr.contains('T')) {
                final parts = dateStr.split('-');
                final day = int.parse(parts[0]);
                final month = int.parse(parts[1]);
                final year = int.parse(parts[2]);
                parsedDate = DateTime(year, month, day);
              }
              else {
                parsedDate = DateTime.now();
              }
              
              date = parsedDate.toIso8601String();
            } catch (e) {
              if (kDebugMode) {
                print('Date parsing error for "$dateStr": $e, using current date');
              }
              date = DateTime.now().toIso8601String();
            }
          }
          
          String payee = getValue('payee', 1)?.toString().trim() ?? '';
          
          // Parse amount with better error handling
          String amountStr = getValue('amount', 2)?.toString().trim() ?? '0';
          double amount = 0.0;
          try {
            // Remove currency symbols and commas
            amountStr = amountStr.replaceAll(RegExp(r'[^\d.-]'), '');
            amount = double.parse(amountStr);
          } catch (e) {
            if (kDebugMode) {
              print('Amount parsing error for "$amountStr": $e, using 0.0');
            }
            amount = 0.0;
          }
          
          String currency = getValue('currency', 3)?.toString().trim().toUpperCase() ?? 'VND';
          // Validate currency
          if (!['VND', 'USD', 'EUR', 'GBP', 'JPY', 'CNY'].contains(currency)) {
            currency = 'VND';
          }
          
          String category = getValue('category', 4)?.toString().trim() ?? '';
          String description = getValue('description', 5)?.toString().trim() ?? '';
          
          // Determine transaction type based on amount
          String type = amount < 0 ? 'expense' : 'income';
          
          // Build account paths
          String assetAccount = 'Assets:Cash';
          String categoryAccount = type == 'expense' 
              ? 'Expenses:${category.isNotEmpty ? category : 'Other'}'
              : 'Income:${category.isNotEmpty ? category : 'General'}';
          
          // Create postings for double-entry accounting
          List<Map<String, dynamic>> postings = [];
          if (type == 'expense') {
            postings.add({
              'account': assetAccount,
              'amount': -amount.abs(),
              'commodity': currency,
            });
            postings.add({
              'account': categoryAccount,
              'amount': amount.abs(),
              'commodity': currency,
            });
          } else {
            postings.add({
              'account': assetAccount,
              'amount': amount.abs(),
              'commodity': currency,
            });
            postings.add({
              'account': categoryAccount,
              'amount': -amount.abs(),
              'commodity': currency,
            });
          }

          transactions.add({
            'date': date,
            'payee': payee,
            'amount': amount,
            'currency': currency,
            'category': categoryAccount,
            'description': description,
            'type': type,
            'account': assetAccount,
            'postings': postings,
          });
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing CSV row $i: $e');
          }
          // Skip this row and continue with next
          continue;
        }
      }

      return transactions;
    } catch (e) {
      if (kDebugMode) {
        print('CSV parsing error: $e');
      }
      rethrow;
    }
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

  Future<List<Map<String, dynamic>>> parseLedgerFile(String ledgerContent) async {
    try {
      final transactions = <Map<String, dynamic>>[];
      final lines = ledgerContent.split('\n');
      
      int i = 0;
      while (i < lines.length) {
        final line = lines[i].trim();
        
        // Skip empty lines and comments
        if (line.isEmpty || line.startsWith(';') || line.startsWith('#')) {
          i++;
          continue;
        }
        
        // Check if line starts with a date (transaction header)
        final dateMatch = RegExp(r'^(\d{4}[-/]\d{2}[-/]\d{2})').firstMatch(line);
        if (dateMatch != null) {
          try {
            final dateStr = dateMatch.group(1)!.replaceAll('/', '-');
            final date = DateTime.parse(dateStr).toIso8601String();
            
            // Extract payee and description
            String payee = '';
            String description = '';
            
            // Format: YYYY-MM-DD * "Payee" "Description"
            final headerMatch = RegExp(r'\d{4}[-/]\d{2}[-/]\d{2}\s+[*!]\s+"([^"]+)"(?:\s+"([^"]+)")?').firstMatch(line);
            if (headerMatch != null) {
              payee = headerMatch.group(1) ?? '';
              description = headerMatch.group(2) ?? '';
            }
            
            // Parse postings (next lines that start with spaces)
            final postings = <Map<String, dynamic>>[];
            i++;
            
            while (i < lines.length) {
              final postingLine = lines[i];
              
              // Check if this is a posting line (starts with whitespace)
              if (postingLine.trim().isEmpty || postingLine.startsWith(';')) {
                i++;
                continue;
              }
              
              if (!postingLine.startsWith(' ') && !postingLine.startsWith('\t')) {
                // Not a posting line, break to process next transaction
                break;
              }
              
              // Parse posting: "    Account:Name    Amount CURRENCY"
              final postingMatch = RegExp(r'\s+([A-Za-z:]+)\s+([-]?\d+(?:\.\d+)?)\s+([A-Z]+)').firstMatch(postingLine);
              if (postingMatch != null) {
                final account = postingMatch.group(1)!;
                final amount = double.parse(postingMatch.group(2)!);
                final currency = postingMatch.group(3)!;
                
                postings.add({
                  'account': account,
                  'amount': amount,
                  'commodity': currency,
                });
              }
              
              i++;
            }
            
            // Determine transaction type and amounts from postings
            if (postings.length >= 2) {
              String type = 'expense';
              double transactionAmount = 0.0;
              String currency = 'VND';
              String category = '';
              String account = 'Assets:Cash';
              
              // Find the asset and category accounts
              for (final posting in postings) {
                final acc = posting['account'] as String;
                final amt = posting['amount'] as double;
                final curr = posting['commodity'] as String;
                
                if (acc.startsWith('Assets:')) {
                  account = acc;
                  transactionAmount = amt;
                  currency = curr;
                } else if (acc.startsWith('Expenses:')) {
                  category = acc;
                  type = 'expense';
                } else if (acc.startsWith('Income:')) {
                  category = acc;
                  type = 'income';
                }
              }
              
              transactions.add({
                'date': date,
                'payee': payee,
                'description': description,
                'amount': transactionAmount,
                'currency': currency,
                'type': type,
                'account': account,
                'category': category,
                'postings': postings,
              });
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error parsing ledger transaction at line $i: $e');
            }
            i++;
          }
        } else {
          i++;
        }
      }
      
      return transactions;
    } catch (e) {
      if (kDebugMode) {
        print('Ledger parsing error: $e');
      }
      rethrow;
    }
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
      
      // Notify listeners of transaction update
      notifyTransactionUpdate();

      // AI auto-categorization (non-blocking)
      _autoCategorizeTransaction(transaction);

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

  /// Fire-and-forget AI categorization after transaction is saved.
  Future<void> _autoCategorizeTransaction(Map<String, dynamic> transaction) async {
    try {
      if (_currentUserId == null) return;

      // Build a Transaction object from the map for the AI service
      final txn = Transaction(
        date: _parseDateForAI(transaction),
        payee: transaction['payee'] as String? ?? '',
        description: transaction['description'] as String? ?? '',
        postings: _parsePostingsForAI(transaction),
      );

      // Get user's existing accounts from recent transactions
      final recentTxns = await getTransactions();
      final accounts = recentTxns
          .expand((t) => t.postings.map((p) => p.account))
          .toSet()
          .toList();

      if (accounts.isEmpty) return;

      // Get past corrections for few-shot learning
      final correctionMaps = await _db.getAICorrections('categorize', limit: 10);
      final corrections = correctionMaps.map((m) => Correction.fromMap(m)).toList();

      final suggestion = await _aiService.categorizeTransaction(txn, accounts, corrections);

      if (suggestion != null && suggestion.isHighConfidence) {
        // Update the transaction's category in the database
        final db = await _db.database;
        final txnId = transaction['transaction_id'] as String?;
        if (txnId != null) {
          await db.update(
            'transactions',
            {'category': suggestion.account},
            where: 'transaction_id = ?',
            whereArgs: [txnId],
          );

          if (kDebugMode) {
            print('AI auto-categorized "$txnId" as "${suggestion.account}" '
                '(confidence: ${suggestion.confidence})');
          }

          notifyTransactionUpdate();
        }
      }
    } catch (e) {
      // AI categorization is non-critical — log and continue
      if (kDebugMode) {
        print('AI auto-categorize error: $e');
      }
    }
  }

  int _parseDateForAI(Map<String, dynamic> transaction) {
    final dateValue = transaction['date'];
    if (dateValue is int) return dateValue;
    if (dateValue is String) {
      final parsed = DateTime.tryParse(dateValue);
      if (parsed != null) return parsed.millisecondsSinceEpoch ~/ 1000;
    }
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  List<Posting> _parsePostingsForAI(Map<String, dynamic> transaction) {
    final postingsData = transaction['postings'];
    if (postingsData is List) {
      return postingsData
          .map((p) => Posting.fromJson(p as Map<String, dynamic>))
          .toList();
    }
    return [];
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

