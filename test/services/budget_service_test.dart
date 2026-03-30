import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plutus_fe_prototype/models/budget_model.dart';
import 'package:plutus_fe_prototype/services/budget_service.dart';

import '../helpers/mock_services.mocks.dart';

void main() {
  late MockIDatabaseService mockDb;
  late BudgetService service;

  const int userId = 1;

  Map<String, dynamic> budgetToDbMap({
    required int id,
    required int uid,
    required String name,
    String mode = 'spending_limit',
    String periodType = 'monthly',
    String currencyCode = 'USD',
    int isActive = 1,
    String? periodStart,
  }) {
    return {
      'id': id,
      'user_id': uid,
      'name': name,
      'mode': mode,
      'period_type': periodType,
      'currency_code': currencyCode,
      'is_active': isActive,
      'period_start': periodStart,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> categoryToDbMap({
    required int id,
    required int budgetId,
    required String name,
    List<String> accountPatterns = const ['Expenses'],
    double budgetedAmount = 500.0,
    int rolloverEnabled = 0,
    String rolloverBehavior = 'carry',
    int sortOrder = 0,
    String? icon,
  }) {
    return {
      'id': id,
      'budget_id': budgetId,
      'name': name,
      'account_patterns': jsonEncode(accountPatterns),
      'budgeted_amount': budgetedAmount,
      'rollover_enabled': rolloverEnabled,
      'rollover_behavior': rolloverBehavior,
      'sort_order': sortOrder,
      'icon': icon,
    };
  }

  setUp(() {
    mockDb = MockIDatabaseService();
    service = BudgetService(db: mockDb);
    service.setCurrentUser(userId);
  });

  group('createBudget', () {
    test('creates a new budget and deactivates the existing active one', () async {
      final existingBudgetMap = budgetToDbMap(
        id: 10,
        uid: userId,
        name: 'Old Budget',
        isActive: 1,
      );
      final newBudgetMap = budgetToDbMap(
        id: 11,
        uid: userId,
        name: 'New Budget',
        isActive: 1,
      );

      // First call: return existing budget so it gets deactivated.
      // Subsequent calls (from notifyBudgetUpdate): return the new budget.
      var callCount = 0;
      when(mockDb.getActiveBudgetByUserId(userId))
          .thenAnswer((_) async {
        callCount++;
        if (callCount == 1) return existingBudgetMap;
        return newBudgetMap;
      });
      when(mockDb.updateBudget(any, any)).thenAnswer((_) async {});
      when(mockDb.insertBudget(any)).thenAnswer((_) async => 11);
      when(mockDb.getBudgetCategoriesByBudgetId(11))
          .thenAnswer((_) async => []);

      final budget = await service.createBudget(
        name: 'New Budget',
        mode: BudgetMode.spendingLimit,
        periodType: BudgetPeriodType.monthly,
        currencyCode: 'USD',
      );

      expect(budget.name, 'New Budget');
      expect(budget.id, 11);

      // The old budget (id=10) should have been deactivated
      verify(mockDb.updateBudget(10, argThat(containsPair('is_active', 0))))
          .called(1);
      verify(mockDb.insertBudget(any)).called(1);
    });

    test('throws when no user is set', () async {
      final noUserService = BudgetService(db: mockDb);

      expect(
        () => noUserService.createBudget(
          name: 'Test',
          mode: BudgetMode.spendingLimit,
          periodType: BudgetPeriodType.monthly,
          currencyCode: 'USD',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('getActiveBudget', () {
    test('returns null when no active budget exists', () async {
      when(mockDb.getActiveBudgetByUserId(userId))
          .thenAnswer((_) async => null);

      final result = await service.getActiveBudget();

      expect(result, isNull);
    });

    test('returns budget with its categories', () async {
      final budgetMap = budgetToDbMap(id: 5, uid: userId, name: 'My Budget');
      final cat1 = categoryToDbMap(id: 1, budgetId: 5, name: 'Food',
          accountPatterns: ['Expenses:Food']);
      final cat2 = categoryToDbMap(id: 2, budgetId: 5, name: 'Transport',
          accountPatterns: ['Expenses:Transport']);

      when(mockDb.getActiveBudgetByUserId(userId))
          .thenAnswer((_) async => budgetMap);
      when(mockDb.getBudgetCategoriesByBudgetId(5))
          .thenAnswer((_) async => [cat1, cat2]);

      final budget = await service.getActiveBudget();

      expect(budget, isNotNull);
      expect(budget!.name, 'My Budget');
      expect(budget.categories.length, 2);
      expect(budget.categories[0].name, 'Food');
      expect(budget.categories[1].name, 'Transport');
    });
  });

  group('getAllCategorySpending', () {
    test('matches postings to categories by prefix', () async {
      final cat1 = categoryToDbMap(id: 1, budgetId: 5, name: 'Food',
          accountPatterns: ['Expenses:Food']);
      final cat2 = categoryToDbMap(id: 2, budgetId: 5, name: 'Transport',
          accountPatterns: ['Expenses:Transport']);

      final periodStart = DateTime(2024, 3, 1);
      final periodEnd = DateTime(2024, 3, 31);

      final startTs = periodStart.toIso8601String();
      final endTs = periodEnd.toIso8601String();

      when(mockDb.getBudgetCategoriesByBudgetId(5))
          .thenAnswer((_) async => [cat1, cat2]);
      when(mockDb.getExpensePostingsForPeriod(userId, startTs, endTs))
          .thenAnswer((_) async => [
                {'account': 'Expenses:Food:Groceries', 'amount': 100.0},
                {'account': 'Expenses:Food:Restaurant', 'amount': 50.0},
                {'account': 'Expenses:Transport:Bus', 'amount': 30.0},
                {'account': 'Expenses:Entertainment', 'amount': 200.0},
              ]);

      final spending = await service.getAllCategorySpending(
          5, periodStart, periodEnd);

      expect(spending[1], closeTo(150.0, 0.001)); // Food: 100 + 50
      expect(spending[2], closeTo(30.0, 0.001));  // Transport: 30
    });
  });

  group('getUnbudgetedSpending', () {
    test('returns postings that do not match any category', () async {
      final cat1 = categoryToDbMap(id: 1, budgetId: 5, name: 'Food',
          accountPatterns: ['Expenses:Food']);

      final periodStart = DateTime(2024, 3, 1);
      final periodEnd = DateTime(2024, 3, 31);

      final startTs = periodStart.toIso8601String();
      final endTs = periodEnd.toIso8601String();

      when(mockDb.getBudgetCategoriesByBudgetId(5))
          .thenAnswer((_) async => [cat1]);
      when(mockDb.getExpensePostingsForPeriod(userId, startTs, endTs))
          .thenAnswer((_) async => [
                {'account': 'Expenses:Food:Groceries', 'amount': 100.0},
                {'account': 'Expenses:Entertainment', 'amount': 200.0},
                {'account': 'Expenses:Gifts', 'amount': 75.0},
              ]);

      final unbudgeted = await service.getUnbudgetedSpending(
          5, periodStart, periodEnd);

      expect(unbudgeted.length, 2);
      // Sorted descending by spent
      expect(unbudgeted[0].accountName, 'Expenses:Entertainment');
      expect(unbudgeted[0].spent, closeTo(200.0, 0.001));
      expect(unbudgeted[1].accountName, 'Expenses:Gifts');
      expect(unbudgeted[1].suggestedCategoryName, 'Gifts');
    });
  });

  group('getProjectedSpending', () {
    test('returns currentSpent for a period entirely in the past', () {
      final periodStart = DateTime(2024, 1, 1);
      final periodEnd = DateTime(2024, 1, 31);

      final projected =
          service.getProjectedSpending(300.0, periodStart, periodEnd);

      expect(projected, 300.0);
    });

    test('returns currentSpent for a period entirely in the future', () {
      final periodStart = DateTime.now().add(const Duration(days: 10));
      final periodEnd = DateTime.now().add(const Duration(days: 40));

      final projected =
          service.getProjectedSpending(0.0, periodStart, periodEnd);

      expect(projected, 0.0);
    });
  });
}
