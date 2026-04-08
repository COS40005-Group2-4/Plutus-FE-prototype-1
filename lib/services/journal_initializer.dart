import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../utils/date_format_utils.dart';
import 'interfaces/i_backend_ffi_service.dart';
import 'interfaces/i_database_service.dart';
import 'interfaces/i_transaction_service.dart';
import 'interfaces/i_budget_service.dart';

/// Collects all data from Flutter SQLite and feeds it to the Go backend
/// via [IBackendFfiService.constructJournal].
///
/// Call [initialize] after user login to set up the Go computation engine.
class JournalInitializer {
  final IBackendFfiService _ffiService;
  final IDatabaseService _dbService;
  final ITransactionService _transactionService;
  final IBudgetService _budgetService;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  JournalInitializer({
    required IBackendFfiService ffiService,
    required IDatabaseService dbService,
    required ITransactionService transactionService,
    required IBudgetService budgetService,
  })  : _ffiService = ffiService,
        _dbService = dbService,
        _transactionService = transactionService,
        _budgetService = budgetService;

  /// Reconstruct the Go journal from Flutter SQLite data.
  /// Safe to call multiple times (e.g., after backup restore).
  Future<void> initialize() async {
    if (!_ffiService.isAvailable) {
      debugPrint('JournalInitializer: FFI not available, skipping');
      return;
    }

    try {
      // 1. Collect transactions
      final transactions = await _transactionService.getTransactions();
      final List<Map<String, dynamic>> txJsonList = transactions.map((tx) {
        final postings = tx.postings.map((p) => {
          'account': p.account,
          'amount': {
            'value': p.amount,
            'commodity': p.commodity,
          },
        }).toList();

        return {
          'date': toCustomDate(
            DateTime.fromMillisecondsSinceEpoch(tx.date * 1000),
          ),
          'payee': tx.payee,
          'desc': tx.description,
          'postings': postings,
        };
      }).toList();

      // 2. Collect budgets from the active budget's categories
      final List<Map<String, dynamic>> budgetJsonList = [];
      final activeBudget = await _budgetService.getActiveBudget();
      if (activeBudget != null) {
        for (final category in activeBudget.categories) {
          // Each category has account patterns and a budgeted amount
          for (final pattern in category.accountPatterns) {
            budgetJsonList.add({
              'account': pattern,
              'amount': {
                'value': category.budgetedAmount,
                'commodity': activeBudget.currencyCode,
              },
            });
          }
        }
      }

      // 3. Rates — currently stored implicitly via investment transactions.
      // The Go backend infers rates from investment transactions automatically.
      // Explicit rates can be added later if the app stores them.
      final List<Map<String, dynamic>> ratesJsonList = [];

      // 4. Build JournalJSON and send to Go
      final journalJson = jsonEncode({
        'transactions': txJsonList,
        'budgets': budgetJsonList,
        'rates': ratesJsonList,
      });

      final result = _ffiService.constructJournal(journalJson);
      final decoded = jsonDecode(result) as Map<String, dynamic>;

      if (decoded['code'] == 200) {
        _isInitialized = true;
        debugPrint('JournalInitializer: Journal constructed with '
            '${txJsonList.length} transactions, '
            '${budgetJsonList.length} budgets');
      } else {
        debugPrint('JournalInitializer: Failed — ${decoded['message']}');
      }
    } catch (e) {
      debugPrint('JournalInitializer: Error during initialization — $e');
    }
  }
}
