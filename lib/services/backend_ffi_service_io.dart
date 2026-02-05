// Native implementation for desktop/mobile platforms
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'dart:convert';

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

class BackendFfiService {
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

  bool _isInitialized = false;
  bool _hasError = false;

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
        _lib = DynamicLibrary.open('libplutus.dylib');
      } else {
        _lib = DynamicLibrary.open('libplutus.so');
      }

      _bootstrap = _lib.lookupFunction<BootstrapFunc, Bootstrap>('Bootstrap');
      _import = _lib.lookupFunction<ImportFunc, Import>('Import');
      _incomeReport = _lib.lookupFunction<IncomeReportFunc, IncomeReport>('IncomeReport');
      _transactionHistory = _lib.lookupFunction<TransactionHistoryFunc, TransactionHistory>('TransactionHistory');
      _saveTransaction = _lib.lookupFunction<SaveTransactionFunc, SaveTransaction>('SaveTransaction');
      _freeString = _lib.lookupFunction<FreeStringFunc, FreeString>('FreeString');

      // Bootstrap DB
      final resultPtr = _bootstrap();
      final result = resultPtr.toDartString();
      _freeString(resultPtr);
      
      if (result.isNotEmpty) {
        print('Backend Bootstrap Error: $result');
        _hasError = true;
      } else {
        _isInitialized = true;
        print('Backend FFI Initialized');
      }
    } catch (e) {
      print('Failed to load backend library: $e');
      _hasError = true;
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
    if (!isAvailable) throw Exception("Backend FFI not available");

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
    if (!isAvailable) throw Exception("Backend FFI not available");

    final filePathPtr = filePath.toNativeUtf8();
    
    try {
      _import(filePathPtr);
    } finally {
      malloc.free(filePathPtr);
    }
  }
}
