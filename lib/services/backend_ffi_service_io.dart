// Native implementation for desktop/mobile platforms
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'dart:convert';
import 'interfaces/i_backend_ffi_service.dart';

typedef BootstrapFunc = Pointer<Utf8> Function();
typedef Bootstrap = Pointer<Utf8> Function();

typedef ImportFunc = Void Function(Pointer<Utf8>);
typedef Import = void Function(Pointer<Utf8>);

typedef IncomeReportFunc = Pointer<Utf8> Function(Bool);
typedef IncomeReport = Pointer<Utf8> Function(bool);

typedef TransactionHistoryFunc = Pointer<Utf8> Function(Int32, Int32);
typedef TransactionHistory = Pointer<Utf8> Function(int, int);

typedef SaveTransactionFunc = Pointer<Utf8> Function(Pointer<Utf8>);
typedef SaveTransaction = Pointer<Utf8> Function(Pointer<Utf8>);

typedef FreeStringFunc = Void Function(Pointer<Utf8>);
typedef FreeString = void Function(Pointer<Utf8>);

typedef GetROIFunc = Pointer<Utf8> Function();
typedef GetROI = Pointer<Utf8> Function();

typedef GetROIWithCurrencyFunc = Pointer<Utf8> Function(Pointer<Utf8>);
typedef GetROIWithCurrency = Pointer<Utf8> Function(Pointer<Utf8>);

typedef GetInvestmentListFunc = Pointer<Utf8> Function();
typedef GetInvestmentList = Pointer<Utf8> Function();

typedef GetInvestmentDetailFunc = Pointer<Utf8> Function(Pointer<Utf8>);
typedef GetInvestmentDetail = Pointer<Utf8> Function(Pointer<Utf8>);

typedef DeleteInvestmentFunc = Pointer<Utf8> Function(Pointer<Utf8>);
typedef DeleteInvestment = Pointer<Utf8> Function(Pointer<Utf8>);

typedef SaveInvestmentFunc = Pointer<Utf8> Function(Pointer<Utf8>);
typedef SaveInvestment = Pointer<Utf8> Function(Pointer<Utf8>);

class BackendFfiService implements IBackendFfiService {
  static final BackendFfiService _instance = BackendFfiService._internal();

  factory BackendFfiService() {
    return _instance;
  }

  late DynamicLibrary _lib;
  late Bootstrap _bootstrap;
  late Import _import;
  late IncomeReport _incomeReport;
  late TransactionHistory _transactionHistory;
  late SaveTransaction _saveTransaction;
  late FreeString _freeString;
  late GetROI _getROI;
  GetROIWithCurrency? _getROIWithCurrency;
  late GetInvestmentList _getInvestmentList;
  late GetInvestmentDetail _getInvestmentDetail;
  late DeleteInvestment _deleteInvestment;
  late SaveInvestment _saveInvestment;

  bool _isInitialized = false;
  bool _hasError = false;
  String _initError = '';

  BackendFfiService._internal() {
    _init();
  }

  void _init() {
    try {
      String libPath;
      if (Platform.isWindows) {
        // Try multiple locations for the DLL
        final possiblePaths = [
          'libplutus.dll', // Current directory
          '../libplutus.dll', // Parent directory
          '../../libplutus.dll', // Two levels up (from build/windows/x64/runner/Debug)
          '../../../libplutus.dll', // Three levels up
          '../../../../libplutus.dll', // Four levels up (project root from deep build)
          Platform.resolvedExecutable.replaceAll('plutus_fe_prototype.exe', 'libplutus.dll'), // Same as exe
        ];
        
        libPath = 'libplutus.dll';
        for (final path in possiblePaths) {
          try {
            final file = File(path);
            if (file.existsSync()) {
              libPath = file.absolute.path;
              print('Found DLL at: $libPath');
              break;
            }
          } catch (e) {
            // Continue to next path
          }
        }
        
        _lib = DynamicLibrary.open(libPath);
      } else if (Platform.isMacOS) {
        // On macOS, the working directory during flutter run is unpredictable.
        // Resolve from the executable path or use known absolute locations.
        final exePath = Platform.resolvedExecutable;
        // exePath is like: .../build/macos/Build/Products/Debug/plutus_fe_prototype.app/Contents/MacOS/plutus_fe_prototype
        // Walk up to find the project root (contains pubspec.yaml)
        var dir = File(exePath).parent;
        String? projectRoot;
        for (var i = 0; i < 10; i++) {
          if (File('${dir.path}/pubspec.yaml').existsSync()) {
            projectRoot = dir.path;
            break;
          }
          dir = dir.parent;
        }

        final macPaths = [
          if (projectRoot != null) '$projectRoot/libplutus.dylib',
          if (projectRoot != null) '$projectRoot/Plutus-backend-prototype-2/libplutus.dylib',
          'libplutus.dylib',
          '${Directory.current.path}/libplutus.dylib',
        ];

        String macLibPath = 'libplutus.dylib';
        for (final path in macPaths) {
          try {
            if (File(path).existsSync()) {
              macLibPath = path;
              print('Found dylib at: $macLibPath');
              break;
            }
          } catch (e) {
            // Continue to next path
          }
        }

        _lib = DynamicLibrary.open(macLibPath);
      } else {
        _lib = DynamicLibrary.open('libplutus.so');
      }

      _bootstrap = _lib.lookupFunction<BootstrapFunc, Bootstrap>('Bootstrap');
      _import = _lib.lookupFunction<ImportFunc, Import>('Import');
      _incomeReport = _lib.lookupFunction<IncomeReportFunc, IncomeReport>('IncomeReport');
      _transactionHistory = _lib.lookupFunction<TransactionHistoryFunc, TransactionHistory>('TransactionHistory');
      _saveTransaction = _lib.lookupFunction<SaveTransactionFunc, SaveTransaction>('SaveTransaction');
      _freeString = _lib.lookupFunction<FreeStringFunc, FreeString>('FreeString');
      _getROI = _lib.lookupFunction<GetROIFunc, GetROI>('GetROI');
      
      // Try to load the new function, but don't fail if it doesn't exist
      try {
        _getROIWithCurrency = _lib.lookupFunction<GetROIWithCurrencyFunc, GetROIWithCurrency>('GetROIWithCurrency');
      } catch (e) {
        print('GetROIWithCurrency not available in DLL, will use GetROI instead');
      }
      
      _getInvestmentList = _lib.lookupFunction<GetInvestmentListFunc, GetInvestmentList>('GetInvestmentList');
      _getInvestmentDetail = _lib.lookupFunction<GetInvestmentDetailFunc, GetInvestmentDetail>('GetInvestmentDetail');
      _deleteInvestment = _lib.lookupFunction<DeleteInvestmentFunc, DeleteInvestment>('DeleteInvestment');
      _saveInvestment = _lib.lookupFunction<SaveInvestmentFunc, SaveInvestment>('SaveInvestment');

      // Bootstrap DB
      final resultPtr = _bootstrap();
      final result = resultPtr.toDartString();
      _freeString(resultPtr);
      
      if (result.isNotEmpty) {
        print('Backend Bootstrap Error: $result');
        _hasError = true;
        _initError = result;
      } else {
        _isInitialized = true;
        print('Backend FFI Initialized');
      }
    } catch (e) {
      print('Failed to load backend library: $e');
      _hasError = true;
      _initError = e.toString();
    }
  }

  bool get isAvailable => _isInitialized && !_hasError;

  Future<List<Map<String, dynamic>>> getTransactions() async {
    if (!isAvailable) return [];

    // 2000-01-01 to 2100-01-01
    final start = DateTime(2000).millisecondsSinceEpoch ~/ 1000;
    final end = DateTime(2100).millisecondsSinceEpoch ~/ 1000;

    final resultPtr = _transactionHistory(start, end);
    final result = resultPtr.toDartString();
    _freeString(resultPtr);

    if (result.isEmpty) return [];

    try {
      final decoded = json.decode(result);
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      }
      return [];
    } catch (e) {
      print('Error decoding transaction history: $e');
      return [];
    }
  }

  Future<void> saveTransaction(Map<String, dynamic> transaction) async {
    if (!isAvailable) throw Exception("Backend FFI not available: $_initError");

    final jsonStr = json.encode(transaction);
    final jsonPtr = jsonStr.toNativeUtf8();
    
    final resultPtr = _saveTransaction(jsonPtr);
    final result = resultPtr.toDartString();
    
    malloc.free(jsonPtr);
    _freeString(resultPtr);

    if (result != "Success") {
      throw Exception(result);
    }
  }

  Future<void> importFile(String filePath) async {
    if (!isAvailable) throw Exception("Backend FFI not available: $_initError");

    final filePathPtr = filePath.toNativeUtf8();
    
    try {
      _import(filePathPtr);
    } finally {
      malloc.free(filePathPtr);
    }
  }

  Future<Map<String, dynamic>> getRoiData({String? currency}) async {
    if (!isAvailable) {
      return {
        'roi': '0.00',
        'irr': '0.00',
        'cashflowTotal': '0',
        'currency': currency ?? 'VND',
      };
    }

    try {
      Pointer<Utf8> resultPtr;
      
      // Try to use the new function with currency if available
      if (currency != null && currency.isNotEmpty && _getROIWithCurrency != null) {
        try {
          final currencyPtr = currency.toNativeUtf8();
          resultPtr = _getROIWithCurrency!(currencyPtr);
          malloc.free(currencyPtr);
        } catch (e) {
          print('GetROIWithCurrency failed, using GetROI: $e');
          resultPtr = _getROI();
        }
      } else {
        resultPtr = _getROI();
      }
      
      final result = resultPtr.toDartString();
      _freeString(resultPtr);

      if (result.isEmpty || result.startsWith('Error:')) {
        print('ROI Error: $result');
        return {
          'roi': '0.00',
          'irr': '0.00',
          'cashflowTotal': '0',
          'currency': currency ?? 'VND',
        };
      }

      final decoded = json.decode(result);
      return Map<String, dynamic>.from(decoded);
    } catch (e) {
      print('Error getting ROI data: $e');
      return {
        'roi': '0.00',
        'irr': '0.00',
        'cashflowTotal': '0',
        'currency': currency ?? 'VND',
      };
    }
  }

  Future<Map<String, dynamic>> getInvestmentList() async {
    if (!isAvailable) throw Exception("Backend FFI not available: $_initError");

    final resultPtr = _getInvestmentList();
    final result = resultPtr.toDartString();
    _freeString(resultPtr);

    if (result.isEmpty) {
      throw Exception("Empty response from backend");
    }

    try {
      final decoded = json.decode(result);
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('error')) {
          throw Exception(decoded['error']);
        }
        return decoded;
      }
      throw Exception("Invalid response format");
    } catch (e) {
      throw Exception('Error decoding investment list: $e');
    }
  }

  Future<Map<String, dynamic>> getInvestmentDetail(String commodity) async {
    if (!isAvailable) throw Exception("Backend FFI not available: $_initError");

    final commodityPtr = commodity.toNativeUtf8();
    final resultPtr = _getInvestmentDetail(commodityPtr);
    final result = resultPtr.toDartString();
    
    malloc.free(commodityPtr);
    _freeString(resultPtr);

    if (result.isEmpty) {
      throw Exception("Empty response from backend");
    }

    try {
      final decoded = json.decode(result);
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('error')) {
          throw Exception(decoded['error']);
        }
        return decoded;
      }
      throw Exception("Invalid response format");
    } catch (e) {
      throw Exception('Error decoding investment detail: $e');
    }
  }

  Future<void> deleteInvestment(String investmentId) async {
    if (!isAvailable) throw Exception("Backend FFI not available: $_initError");

    print('FFI: Deleting investment with ID: $investmentId');
    
    final idPtr = investmentId.toNativeUtf8();
    final resultPtr = _deleteInvestment(idPtr);
    final result = resultPtr.toDartString();
    
    malloc.free(idPtr);
    _freeString(resultPtr);

    print('FFI: Delete response: $result');

    if (result.isEmpty) {
      throw Exception("Empty response from backend");
    }

    try {
      final decoded = json.decode(result);
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('error')) {
          throw Exception(decoded['error']);
        }
        if (decoded['success'] != true) {
          throw Exception(decoded['message'] ?? 'Delete failed');
        }
        print('FFI: Investment deleted successfully');
      } else {
        throw Exception("Invalid response format");
      }
    } catch (e) {
      throw Exception('Error deleting investment: $e');
    }
  }

  Future<String> saveInvestment(Map<String, dynamic> investmentData) async {
    if (!isAvailable) throw Exception("Backend FFI not available: $_initError");

    print('FFI: Saving investment: $investmentData');

    final jsonStr = json.encode(investmentData);
    final jsonPtr = jsonStr.toNativeUtf8();
    
    final resultPtr = _saveInvestment(jsonPtr);
    final result = resultPtr.toDartString();
    
    malloc.free(jsonPtr);
    _freeString(resultPtr);

    print('FFI: Save response: $result');

    if (result.isEmpty) {
      throw Exception("Empty response from backend");
    }

    try {
      final decoded = json.decode(result);
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('error')) {
          throw Exception(decoded['error']);
        }
        if (decoded['success'] != true) {
          throw Exception(decoded['message'] ?? 'Save failed');
        }
        print('FFI: Investment saved successfully with ID: ${decoded['id']}');
        return decoded['id'] as String;
      } else {
        throw Exception("Invalid response format");
      }
    } catch (e) {
      throw Exception('Error saving investment: $e');
    }
  }
}
