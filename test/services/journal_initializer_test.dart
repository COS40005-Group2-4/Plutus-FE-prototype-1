import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plutus_fe_prototype/services/journal_initializer.dart';

import '../helpers/mock_services.mocks.dart';
import '../helpers/test_fixtures.dart';

void main() {
  late MockIBackendFfiService ffi;
  late MockIDatabaseService db;
  late MockITransactionService tx;
  late MockIBudgetService budget;
  late JournalInitializer initializer;

  setUp(() {
    ffi = MockIBackendFfiService();
    db = MockIDatabaseService();
    tx = MockITransactionService();
    budget = MockIBudgetService();
    initializer = JournalInitializer(
      ffiService: ffi,
      dbService: db,
      transactionService: tx,
      budgetService: budget,
    );
  });

  String okJson() => jsonEncode({'code': 200, 'message': 'ok'});
  String errJson() => jsonEncode({'code': 500, 'message': 'boom'});

  test('starts uninitialized', () {
    expect(initializer.isInitialized, isFalse);
  });

  test('skips work when FFI is unavailable', () async {
    when(ffi.isAvailable).thenReturn(false);

    await initializer.initialize();

    expect(initializer.isInitialized, isFalse);
    verifyNever(tx.getTransactions());
    verifyNever(budget.getActiveBudget());
    verifyNever(ffi.constructJournal(any));
  });

  test('initializes with empty journal when no data present', () async {
    when(ffi.isAvailable).thenReturn(true);
    when(tx.getTransactions()).thenAnswer((_) async => []);
    when(budget.getActiveBudget()).thenAnswer((_) async => null);
    when(ffi.constructJournal(any)).thenReturn(okJson());

    await initializer.initialize();

    expect(initializer.isInitialized, isTrue);
    final captured = verify(ffi.constructJournal(captureAny)).captured.single as String;
    final decoded = jsonDecode(captured) as Map<String, dynamic>;
    expect(decoded['transactions'], isEmpty);
    expect(decoded['budgets'], isEmpty);
    expect(decoded['rates'], isEmpty);
  });

  test('serialises transactions and budget categories into the journal', () async {
    when(ffi.isAvailable).thenReturn(true);
    when(tx.getTransactions()).thenAnswer((_) async => [createTestTransaction()]);
    when(budget.getActiveBudget()).thenAnswer((_) async => createTestBudget(
          currencyCode: 'VND',
          categories: [
            createTestBudgetCategory(
              accountPatterns: const ['Expenses:Food', 'Expenses:Dining'],
              budgetedAmount: 500,
            ),
          ],
        ));
    when(ffi.constructJournal(any)).thenReturn(okJson());

    await initializer.initialize();

    expect(initializer.isInitialized, isTrue);
    final captured = verify(ffi.constructJournal(captureAny)).captured.single as String;
    final decoded = jsonDecode(captured) as Map<String, dynamic>;

    expect((decoded['transactions'] as List), hasLength(1));
    final txEntry = (decoded['transactions'] as List).first as Map<String, dynamic>;
    expect(txEntry['payee'], 'Test Payee');
    expect((txEntry['postings'] as List), hasLength(2));

    // One budget entry per (category, account-pattern) pair.
    expect((decoded['budgets'] as List), hasLength(2));
    final firstBudget = (decoded['budgets'] as List).first as Map<String, dynamic>;
    expect(firstBudget['account'], 'Expenses:Food');
    expect((firstBudget['amount'] as Map)['value'], 500);
    expect((firstBudget['amount'] as Map)['commodity'], 'VND');
  });

  test('does not mark initialized when FFI returns non-200', () async {
    when(ffi.isAvailable).thenReturn(true);
    when(tx.getTransactions()).thenAnswer((_) async => []);
    when(budget.getActiveBudget()).thenAnswer((_) async => null);
    when(ffi.constructJournal(any)).thenReturn(errJson());

    await initializer.initialize();

    expect(initializer.isInitialized, isFalse);
  });

  test('swallows exceptions from underlying services', () async {
    when(ffi.isAvailable).thenReturn(true);
    when(tx.getTransactions()).thenThrow(StateError('db locked'));

    // Should not propagate; isInitialized stays false.
    await initializer.initialize();

    expect(initializer.isInitialized, isFalse);
    verifyNever(ffi.constructJournal(any));
  });
}
