// Web implementation that calls the Go backend via HTTP API Gateway
// instead of FFI (which is not available on web).
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import 'interfaces/i_backend_ffi_service.dart';

class BackendFfiService implements IBackendFfiService {
  static final BackendFfiService _instance = BackendFfiService._internal();

  factory BackendFfiService() {
    return _instance;
  }

  BackendFfiService._internal();

  String get _baseUrl => ApiConfig.baseUrl;

  @override
  bool get isAvailable => ApiConfig.isConfigured;

  /// Gets the stored Google OAuth access token for API authorization.
  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('google_access_token');
  }

  /// Builds authorized headers for API requests.
  Future<Map<String, String>> _headers() async {
    final token = await _getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Makes a GET request to the API.
  Future<http.Response> _get(String path, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: queryParams);
    final headers = await _headers();
    final response = await http.get(uri, headers: headers);
    if (response.statusCode >= 400) {
      throw Exception('API error ${response.statusCode}: ${response.body}');
    }
    return response;
  }

  /// Makes a POST request to the API.
  Future<http.Response> _post(String path, {Object? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = await _headers();
    final response = await http.post(
      uri,
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    if (response.statusCode >= 400) {
      throw Exception('API error ${response.statusCode}: ${response.body}');
    }
    return response;
  }

  /// Makes a DELETE request to the API.
  Future<http.Response> _delete(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = await _headers();
    final response = await http.delete(uri, headers: headers);
    if (response.statusCode >= 400) {
      throw Exception('API error ${response.statusCode}: ${response.body}');
    }
    return response;
  }

  @override
  Future<List<Map<String, dynamic>>> getTransactions() async {
    if (!isAvailable) return [];
    final response = await _get('/transactions');
    final List<dynamic> data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  }

  @override
  Future<void> saveTransaction(Map<String, dynamic> transaction) async {
    await _post('/transactions', body: transaction);
  }

  @override
  Future<void> importFile(String filePath) async {
    // For web, file import sends the file content as base64
    // The actual file reading is handled by the caller
    await _post('/import', body: {'file_content': filePath});
  }

  @override
  Future<Map<String, dynamic>> getRoiData({String? currency}) async {
    if (!isAvailable) {
      return {
        'roi': '0.00',
        'irr': '0.00',
        'cashflowTotal': '0',
        'currency': currency ?? 'VND',
      };
    }
    final queryParams = <String, String>{};
    if (currency != null) queryParams['currency'] = currency;
    final response = await _get('/reports/roi', queryParams: queryParams);
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> getInvestmentList() async {
    final response = await _get('/investments');
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> getInvestmentDetail(String commodity) async {
    final response = await _get('/investments/$commodity');
    return jsonDecode(response.body);
  }

  @override
  Future<void> deleteInvestment(String investmentId) async {
    await _delete('/investments/$investmentId');
  }

  @override
  Future<String> saveInvestment(Map<String, dynamic> investmentData) async {
    final response = await _post('/investments', body: investmentData);
    final result = jsonDecode(response.body);
    return result['id'] ?? '';
  }
}
