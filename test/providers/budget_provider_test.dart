import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:plutus_fe_prototype/models/budget_model.dart';
import 'package:plutus_fe_prototype/models/transaction_model.dart';
import 'package:plutus_fe_prototype/providers/budget_notifier.dart';
import 'package:plutus_fe_prototype/services/budget_notification_service.dart';
import 'package:plutus_fe_prototype/services/interfaces/i_budget_service.dart';
import 'package:plutus_fe_prototype/services/interfaces/i_transaction_service.dart';
import '../helpers/mock_services.mocks.dart';
import '../helpers/test_fixtures.dart';

void main() {
  late MockIBudgetService mockBudgetService;
  late MockITransactionService mockTransactionService;
  late BudgetNotificationService notificationService;
  late StreamController<Budget?> budgetStreamController;
  late StreamController<List<Transaction>> transactionStreamController;
  final GetIt sl = GetIt.instance;

  setUp(() async {
    mockBudgetService = MockIBudgetService();
    mockTransactionService = MockITransactionService();
    budgetStreamController = StreamController<Budget?>.broadcast();
    transactionStreamController = StreamController<List<Transaction>>.broadcast();

    // Stub streams
    when(mockBudgetService.budgetStream)
        .thenAnswer((_) => budgetStreamController.stream);
    when(mockTransactionService.transactionStream)
        .thenAnswer((_) => transactionStreamController.stream);

    notificationService =
        BudgetNotificationService(budgetService: mockBudgetService);

    // Register mocks in GetIt
    Future<void> register<T extends Object>(T instance) async {
      if (sl.isRegistered<T>()) await sl.unregister<T>();
      sl.registerSingleton<T>(instance);
    }

    await register<IBudgetService>(mockBudgetService);
    await register<ITransactionService>(mockTransactionService);
    await register<BudgetNotificationService>(notificationService);
  });

  tearDown(() async {
    await budgetStreamController.close();
    await transactionStreamController.close();

    Future<void> unregister<T extends Object>() async {
      if (sl.isRegistered<T>()) await sl.unregister<T>();
    }

    await unregister<IBudgetService>();
    await unregister<ITransactionService>();
    await unregister<BudgetNotificationService>();
  });

  ProviderContainer makeContainer() {
    return ProviderContainer();
  }

  group('BudgetNotifier', () {
    test('loadBudget sets activeBudget and computes spending', () async {
      final category =
          createTestBudgetCategory(id: 10, budgetedAmount: 400.0);
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

      final container = makeContainer();
      addTearDown(container.dispose);

      // Wait for async build to complete
      final state = await container.read(budgetNotifierProvider.future);

      expect(state.activeBudget, isNotNull);
      expect(state.categorySpending.length, equals(1));

      final cs = state.categorySpending.first;
      expect(cs.spent, equals(250.0));
      expect(cs.remaining, equals(150.0));
      expect(state.totalBudgeted, equals(400.0));
      expect(state.totalSpent, equals(250.0));
    });

    test('loadBudget handles null budget', () async {
      when(mockBudgetService.getActiveBudget())
          .thenAnswer((_) async => null);

      final container = makeContainer();
      addTearDown(container.dispose);

      final state = await container.read(budgetNotifierProvider.future);

      expect(state.activeBudget, isNull);
      expect(state.categorySpending, isEmpty);
    });

    test('navigatePeriod moves monthly period forward', () async {
      final category =
          createTestBudgetCategory(id: 10, budgetedAmount: 400.0);
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

      final container = makeContainer();
      addTearDown(container.dispose);

      final initialState = await container.read(budgetNotifierProvider.future);
      final startBefore = initialState.currentPeriodStart;

      final notifier = container.read(budgetNotifierProvider.notifier);
      await notifier.navigatePeriod(1);

      final state = await container.read(budgetNotifierProvider.future);
      expect(
        state.currentPeriodStart.month,
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

      final container = makeContainer();
      addTearDown(container.dispose);

      final state = await container.read(budgetNotifierProvider.future);

      expect(state.overBudgetCount, equals(1));

      final food =
          state.categorySpending.firstWhere((cs) => cs.category.id == 10);
      final transport =
          state.categorySpending.firstWhere((cs) => cs.category.id == 11);
      expect(food.status, equals(BudgetStatus.overBudget));
      expect(transport.status, equals(BudgetStatus.onTrack));
    });
  });
}
