// Stub implementation for web platform where dart:ffi is not available
import 'interfaces/i_backend_ffi_service.dart';

class BackendFfiService implements IBackendFfiService {
  static final BackendFfiService _instance = BackendFfiService._internal();

  factory BackendFfiService() {
    return _instance;
  }

  BackendFfiService._internal() {
    // No initialization needed for web stub
    print('Backend FFI Service (Web Stub) - FFI not available on web platform');
  }

  @override
  bool get isAvailable => false;

  @override
  Future<List<Map<String, dynamic>>> getTransactions() async {
    return [];
  }

  @override
  Future<void> saveTransaction(Map<String, dynamic> transaction) async {
    throw UnsupportedError('FFI backend not available on web platform');
  }

  @override
  Future<void> importFile(String filePath) async {
    throw UnsupportedError('FFI file import not available on web platform');
  }

  @override
  Future<Map<String, dynamic>> getRoiData({String? currency}) async {
    return {
      'roi': '0.00',
      'irr': '0.00',
      'cashflowTotal': '0',
      'currency': currency ?? 'VND',
    };
  }

  @override
  Future<Map<String, dynamic>> getInvestmentList() async {
    throw UnimplementedError('Investment list not available on web platform');
  }

  @override
  Future<Map<String, dynamic>> getInvestmentDetail(String commodity) async {
    throw UnimplementedError('Investment detail not available on web platform');
  }

  @override
  Future<void> deleteInvestment(String investmentId) async {
    throw UnimplementedError('Investment delete not available on web platform');
  }

  @override
  Future<String> saveInvestment(Map<String, dynamic> investmentData) async {
    throw UnimplementedError('Investment save not available on web platform');
  }
}
