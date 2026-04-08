import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'interfaces/i_backend_ffi_service.dart';

// FFI typedefs for functions that take a C string and return a C string
typedef _StringToStringC = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _StringToStringDart = Pointer<Utf8> Function(Pointer<Utf8>);

// FFI typedefs for functions that take nothing and return a C string
typedef _VoidToStringC = Pointer<Utf8> Function();
typedef _VoidToStringDart = Pointer<Utf8> Function();

// FFI typedef for FreeString
typedef _FreeStringC = Void Function(Pointer<Utf8>);
typedef _FreeStringDart = void Function(Pointer<Utf8>);

class BackendFfiService implements IBackendFfiService {
  static final BackendFfiService _instance = BackendFfiService._internal();

  factory BackendFfiService() => _instance;

  late DynamicLibrary _lib;

  // FFI function pointers
  late _StringToStringDart _constructJournal;
  late _VoidToStringDart _dumpJournal;
  late _StringToStringDart _addTransaction;
  late _StringToStringDart _addInvestment;
  late _StringToStringDart _addBudget;
  late _StringToStringDart _deleteBudget;
  late _StringToStringDart _budgetReport;
  late _StringToStringDart _addRate;
  late _StringToStringDart _getRate;
  late _VoidToStringDart _accountList;
  late _VoidToStringDart _commodities;
  late _StringToStringDart _getInvestmentReport;
  late _VoidToStringDart _getIncomeReport;
  late _StringToStringDart _getSavingsReport;
  late _FreeStringDart _freeString;

  bool _isAvailable = false;

  BackendFfiService._internal() {
    _init();
  }

  void _init() {
    try {
      _lib = _loadLibrary();

      _constructJournal = _lib.lookupFunction<_StringToStringC, _StringToStringDart>('ConstructJournal');
      _dumpJournal = _lib.lookupFunction<_VoidToStringC, _VoidToStringDart>('DumpJournal');
      _addTransaction = _lib.lookupFunction<_StringToStringC, _StringToStringDart>('AddTransaction');
      _addInvestment = _lib.lookupFunction<_StringToStringC, _StringToStringDart>('AddInvestment');
      _addBudget = _lib.lookupFunction<_StringToStringC, _StringToStringDart>('AddBudget');
      _deleteBudget = _lib.lookupFunction<_StringToStringC, _StringToStringDart>('DeleteBudget');
      _budgetReport = _lib.lookupFunction<_StringToStringC, _StringToStringDart>('BudgetReport');
      _addRate = _lib.lookupFunction<_StringToStringC, _StringToStringDart>('AddRate');
      _getRate = _lib.lookupFunction<_StringToStringC, _StringToStringDart>('GetRate');
      _accountList = _lib.lookupFunction<_VoidToStringC, _VoidToStringDart>('AccountList');
      _commodities = _lib.lookupFunction<_VoidToStringC, _VoidToStringDart>('Commodities');
      _getInvestmentReport = _lib.lookupFunction<_StringToStringC, _StringToStringDart>('GetInvestmentReport');
      _getIncomeReport = _lib.lookupFunction<_VoidToStringC, _VoidToStringDart>('GetIncomeReport');
      _getSavingsReport = _lib.lookupFunction<_StringToStringC, _StringToStringDart>('GetSavingsReport');
      _freeString = _lib.lookupFunction<_FreeStringC, _FreeStringDart>('FreeString');

      _isAvailable = true;
      debugPrint('Backend FFI initialized successfully');
    } catch (e) {
      debugPrint('Failed to load backend library: $e');
      _isAvailable = false;
    }
  }

  DynamicLibrary _loadLibrary() {
    if (Platform.isWindows) {
      final possiblePaths = [
        'libplutus.dll',
        '../libplutus.dll',
        '../../libplutus.dll',
        '../../../libplutus.dll',
        '../../../../libplutus.dll',
        Platform.resolvedExecutable.replaceAll('plutus_fe_prototype.exe', 'libplutus.dll'),
      ];

      for (final path in possiblePaths) {
        try {
          if (File(path).existsSync()) {
            debugPrint('Found DLL at: ${File(path).absolute.path}');
            return DynamicLibrary.open(File(path).absolute.path);
          }
        } catch (_) {}
      }
      return DynamicLibrary.open('libplutus.dll');
    } else if (Platform.isMacOS) {
      final exePath = Platform.resolvedExecutable;
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
        if (projectRoot != null) '$projectRoot/Plutus-backend/libplutus.dylib',
        'libplutus.dylib',
        '${Directory.current.path}/libplutus.dylib',
      ];

      for (final path in macPaths) {
        try {
          if (File(path).existsSync()) {
            debugPrint('Found dylib at: $path');
            return DynamicLibrary.open(path);
          }
        } catch (_) {}
      }
      return DynamicLibrary.open('libplutus.dylib');
    } else {
      return DynamicLibrary.open('libplutus.so');
    }
  }

  /// Calls an FFI function that takes a string argument and returns a string.
  String _callWithArg(_StringToStringDart fn, String arg) {
    final argPtr = arg.toNativeUtf8();
    final resultPtr = fn(argPtr);
    final result = resultPtr.toDartString();
    malloc.free(argPtr);
    _freeString(resultPtr);
    return result;
  }

  /// Calls an FFI function that takes no arguments and returns a string.
  String _callNoArg(_VoidToStringDart fn) {
    final resultPtr = fn();
    final result = resultPtr.toDartString();
    _freeString(resultPtr);
    return result;
  }

  @override
  bool get isAvailable => _isAvailable;

  @override
  String constructJournal(String journalJson) => _callWithArg(_constructJournal, journalJson);

  @override
  String dumpJournal() => _callNoArg(_dumpJournal);

  @override
  String addTransaction(String transactionJson) => _callWithArg(_addTransaction, transactionJson);

  @override
  String addInvestment(String transactionJson) => _callWithArg(_addInvestment, transactionJson);

  @override
  String addBudget(String budgetJson) => _callWithArg(_addBudget, budgetJson);

  @override
  String deleteBudget(String accountName) => _callWithArg(_deleteBudget, accountName);

  @override
  String budgetReport(String requestJson) => _callWithArg(_budgetReport, requestJson);

  @override
  String addRate(String rateJson) => _callWithArg(_addRate, rateJson);

  @override
  String getRate(String requestJson) => _callWithArg(_getRate, requestJson);

  @override
  String accountList() => _callNoArg(_accountList);

  @override
  String commodities() => _callNoArg(_commodities);

  @override
  String getInvestmentReport(String requestJson) => _callWithArg(_getInvestmentReport, requestJson);

  @override
  String getIncomeReport() => _callNoArg(_getIncomeReport);

  @override
  String getSavingsReport(String requestJson) => _callWithArg(_getSavingsReport, requestJson);
}
