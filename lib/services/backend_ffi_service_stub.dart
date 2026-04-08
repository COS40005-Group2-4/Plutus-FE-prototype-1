import 'dart:convert';
import 'interfaces/i_backend_ffi_service.dart';

/// Web stub — the Go FFI backend is not available on web.
/// Returns error JSON for all methods.
class BackendFfiService implements IBackendFfiService {
  static final BackendFfiService _instance = BackendFfiService._internal();
  factory BackendFfiService() => _instance;
  BackendFfiService._internal();

  static final String _unavailable = jsonEncode({
    'code': 501,
    'message': 'FFI backend not available on web',
  });

  @override
  bool get isAvailable => false;

  @override
  String constructJournal(String journalJson) => _unavailable;
  @override
  String dumpJournal() => _unavailable;
  @override
  String addTransaction(String transactionJson) => _unavailable;
  @override
  String addInvestment(String transactionJson) => _unavailable;
  @override
  String addBudget(String budgetJson) => _unavailable;
  @override
  String deleteBudget(String accountName) => _unavailable;
  @override
  String budgetReport(String requestJson) => _unavailable;
  @override
  String addRate(String rateJson) => _unavailable;
  @override
  String getRate(String requestJson) => _unavailable;
  @override
  String accountList() => _unavailable;
  @override
  String commodities() => _unavailable;
  @override
  String getInvestmentReport(String requestJson) => _unavailable;
  @override
  String getIncomeReport() => _unavailable;
  @override
  String getSavingsReport(String requestJson) => _unavailable;
}
