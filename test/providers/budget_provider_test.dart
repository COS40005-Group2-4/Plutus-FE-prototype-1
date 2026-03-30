import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plutus_fe_prototype/models/budget_model.dart';
import 'package:plutus_fe_prototype/models/transaction_model.dart';
import 'package:plutus_fe_prototype/providers/budget_provider.dart';
import 'package:plutus_fe_prototype/services/budget_notification_service.dart';
import '../helpers/mock_services.mocks.dart';
import '../helpers/test_fixtures.dart';

void main() {
  late MockIBudgetService mockBudgetService;
  late MockITransactionService mockTransactionService;
  late BudgetNotificationService notificationService;
  late StreamController<Budget?> budgetStreamController;
  late StreamController<List<Transaction>> transactionStreamController;

  setUp(() {
    mockBudgetService = MockIBudgetService();
    mockTransactionService = MockITransactionService();
    budgetStreamController = StreamController<Budget?>.broadcast();
    transactionStreamController = StreamController<List<Transaction>>.broadcast();

    // Stub budgetStream to return our controller's stream
    when(mockBudgetService.budgetStream).thenAnswer((_) => budgetStreamController.stream);
    // Stub transactionStream
    when(mockTransactionService.transactionStream).thenAnswer((_) => transactionStreamController.stream);

    notificationService = BudgetNotificationService(budgetService: mockBudgetService);
  });

  tearDown(() {
    budgetStreamController.close();
    transactionStreamController.close();
  });

  BudgetProvider createProvider() {
    return BudgetProvider(
      budgetService: mockBudgetService,
      notificationService: notificationService,
      transactionService: mockTransactionService,
    );
  }

  group('BudgetProvider', () {
    test('loadBudget sets activeBudget and computes spending', () async {
      final category = createTestBudgetCategory(id: 10, budgetedAmount: 400.0);
      final budget = createTestBudget(id: 1, categories: [category]);

      when(mockBudgetService.getActiveBudget())
          .thenAnswer((_) async => budget);
      when(mockBudgetService.getAllCategorySpending(any, any, any))
          .thenAnswer((_) async => {10: 250.0});
      when(mockBudgetService.getPeriodForCategory(any, any))
          .thenAnswer((_) async => null);
      when(mockBudgetService.getProjectedSpending(any, any, any))
          .thenReturn(350.0);
      when(mockBudgetService.getUnbudgetedSpending(any, any, any))
          .thenAnswer((_) async => []);
      when(mockBudgetService.getNotificationRules(any))
          .thenAnswer((_) async => []);

      final provider = createProvider();
      addTearDown(provider.dispose);

      await provider.loadBudget();

      expect(provider.activeBudget, isNotNull);
      expect(provider.categorySpending.length, equals(1));

      final cs = provider.categorySpending.first;
      expect(cs.spent, equals(250.0));
      expect(cs.remaining, equals(150.0));
      expect(provider.totalBudgeted, equals(400.0));
      expect(provider.totalSpent, equals(250.0));
      expect(provider.isLoading, isFalse);
    });

    test('loadBudget handles null budget', () async {
      when(mockBudgetService.getActiveBudget())
          .thenAnswer((_) async => null);

      final provider = createProvider();
      addTearDown(provider.dispose);

      await provider.loadBudget();

      expect(provider.activeBudget, isNull);
      expect(provider.categorySpending, isEmpty);
      expect(provider.isLoading, isFalse);
    });

    test('navigatePeriod moves monthly period forward', () async {
      final category = createTestBudgetCategory(id: 10, budgetedAmount: 400.0);
      final budget = createTestBudget(
        id: 1,
        periodType: BudgetPeriodType.monthly,
        categories: [category],
      );

      when(mockBudgetService.getActiveBudget())
          .thenAnswer((_) async => budget);
      when(mockBudgetService.getAllCategorySpending(any, any, any))
          .thenAnswer((_) async => {10: 100.0});
      when(mockBudgetService.getPeriodForCategory(any, any))
          .thenAnswer((_) async => null);
      when(mockBudgetService.getProjectedSpending(any, any, any))
          .thenReturn(200.0);
      when(mockBudgetService.getUnbudgetedSpending(any, any, any))
          .thenAnswer((_) async => []);
      when(mockBudgetService.getNotificationRules(any))
          .thenAnswer((_) async => []);

      final provider = createProvider();
      addTearDown(provider.dispose);

      await provider.loadBudget();

      final startBefore = provider.currentPeriodStart;

      await provider.navigatePeriod(1);

      expect(
        provider.currentPeriodStart.month,
        equals(startBefore.month == 12 ? 1 : startBefore.month + 1),
      );
    });

    test('overBudgetCount counts correctly', () async {
      // Category 1: spent 380 / budget 400 = 95% → overBudget
      final cat1 = createTestBudgetCategory(
        id: 10,
        budgetedAmount: 400.0,
        name: 'Food',
      );
      // Category 2: spent 200 / budget 400 = 50% → onTrack
      final cat2 = createTestBudgetCategory(
        id: 11,
        budgetedAmount: 400.0,
        name: 'Transport',
      );
      final budget = createTestBudget(id: 1, categories: [cat1, cat2]);

      when(mockBudgetService.getActiveBudget())
          .thenAnswer((_) async => budget);
      when(mockBudgetService.getAllCategorySpending(any, any, any))
          .thenAnswer((_) async => {10: 380.0, 11: 200.0});
      when(mockBudgetService.getPeriodForCategory(any, any))
          .thenAnswer((_) async => null);
      when(mockBudgetService.getProjectedSpending(any, any, any))
          .thenReturn(400.0);
      when(mockBudgetService.getUnbudgetedSpending(any, any, any))
          .thenAnswer((_) async => []);
      when(mockBudgetService.getNotificationRules(any))
          .thenAnswer((_) async => []);

      final provider = createProvider();
      addTearDown(provider.dispose);

      await provider.loadBudget();

      expect(provider.overBudgetCount, equals(1));

      // Verify statuses individually
      final food = provider.categorySpending.firstWhere(
        (cs) => cs.category.id == 10,
      );
      final transport = provider.categorySpending.firstWhere(
        (cs) => cs.category.id == 11,
      );
      expect(food.status, equals(BudgetStatus.overBudget));
      expect(transport.status, equals(BudgetStatus.onTrack));
    });
  });
}
