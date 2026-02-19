// Stub implementation for web platform where dart:ffi is not available
import 'dart:convert';

class BackendFfiService {
  static final BackendFfiService _instance = BackendFfiService._internal();

  factory BackendFfiService() {
    return _instance;
  }

  BackendFfiService._internal() {
    // No initialization needed for web stub
    print('Backend FFI Service (Web Stub) - FFI not available on web platform');
  }

  // Always false for web
  bool get isAvailable => false;

  Future<List<Map<String, dynamic>>> getTransactions() async {
    // Return empty list - web will rely on HTTP backend or local database
    return [];
  }

  Future<void> saveTransaction(Map<String, dynamic> transaction) async {
    // No-op for web - transactions are saved via local database
    throw UnsupportedError('FFI backend not available on web platform');
  }

  Future<void> importFile(String filePath) async {
    // No-op for web - file import handled differently
    throw UnsupportedError('FFI file import not available on web platform');
  }

  Future<Map<String, dynamic>> getRoiData() async {
    // Return default values for web
    return {
      'roi': '0.00',
      'irr': '0.00',
      'cashflowTotal': '0',
    };
  }

  Future<Map<String, dynamic>> getInvestmentList() async {
    throw UnimplementedError('Investment list not available on web platform');
  }

  Future<Map<String, dynamic>> getInvestmentDetail(String commodity) async {
    throw UnimplementedError('Investment detail not available on web platform');
  }
}
