import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/services/backend_ffi_service_stub.dart';

/// The web/stub implementation must safely return error JSON for every
/// FFI call so that web builds (where libplutus is unavailable) degrade
/// gracefully instead of crashing.
void main() {
  late BackendFfiService stub;

  setUp(() {
    stub = BackendFfiService();
  });

  test('reports unavailable on web', () {
    expect(stub.isAvailable, isFalse);
  });

  test('factory returns the same singleton instance', () {
    final a = BackendFfiService();
    final b = BackendFfiService();
    expect(identical(a, b), isTrue);
  });

  group('every FFI method returns well-formed error JSON', () {
    void expectUnavailable(String json) {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      expect(decoded['code'], 501);
      expect(decoded['message'], isA<String>());
      expect(decoded['message'], contains('not available'));
    }

    test('constructJournal', () => expectUnavailable(stub.constructJournal('{}')));
    test('dumpJournal', () => expectUnavailable(stub.dumpJournal()));
    test('addTransaction', () => expectUnavailable(stub.addTransaction('{}')));
    test('addInvestment', () => expectUnavailable(stub.addInvestment('{}')));
    test('addBudget', () => expectUnavailable(stub.addBudget('{}')));
    test('deleteBudget', () => expectUnavailable(stub.deleteBudget('Expenses:Food')));
    test('budgetReport', () => expectUnavailable(stub.budgetReport('{}')));
    test('addRate', () => expectUnavailable(stub.addRate('{}')));
    test('getRate', () => expectUnavailable(stub.getRate('{}')));
    test('accountList', () => expectUnavailable(stub.accountList()));
    test('commodities', () => expectUnavailable(stub.commodities()));
    test('getInvestmentReport', () => expectUnavailable(stub.getInvestmentReport('{}')));
    test('getIncomeReport', () => expectUnavailable(stub.getIncomeReport()));
    test('getSavingsReport', () => expectUnavailable(stub.getSavingsReport('{}')));
  });
}
