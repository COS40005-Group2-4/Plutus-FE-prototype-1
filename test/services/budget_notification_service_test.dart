import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plutus_fe_prototype/models/budget_model.dart';
import 'package:plutus_fe_prototype/services/budget_notification_service.dart';
import '../helpers/mock_services.mocks.dart';
import '../helpers/test_fixtures.dart';

void main() {
  late MockIBudgetService mockBudgetService;
  late BudgetNotificationService notifService;

  setUp(() {
    mockBudgetService = MockIBudgetService();
    notifService = BudgetNotificationService(budgetService: mockBudgetService);
  });

  test('returns empty when no rules exist', () async {
    when(mockBudgetService.getNotificationRules(1)).thenAnswer((_) async => []);
    final alerts = await notifService.checkThresholds(1, DateTime(2026, 3, 1), DateTime(2026, 4, 1));
    expect(alerts, isEmpty);
  });

  test('returns alert when spending exceeds threshold', () async {
    final category = createTestBudgetCategory(id: 10, budgetedAmount: 400);
    final budget = createTestBudget(id: 1, categories: [category]);

    when(mockBudgetService.getNotificationRules(1)).thenAnswer((_) async => [
      NotificationRule(id: 1, budgetCategoryId: 10, thresholdPct: 0.9),
    ]);
    when(mockBudgetService.getAllCategorySpending(1, any, any)).thenAnswer((_) async => {10: 380.0});
    when(mockBudgetService.getActiveBudget()).thenAnswer((_) async => budget);
    when(mockBudgetService.getPeriodForCategory(10, any)).thenAnswer((_) async => null);

    final alerts = await notifService.checkThresholds(1, DateTime(2026, 3, 1), DateTime(2026, 4, 1));
    expect(alerts.length, 1);
    expect(alerts.first.category.id, 10);
    expect(alerts.first.spent, 380.0);
  });

  test('skips disabled rules', () async {
    final category = createTestBudgetCategory(id: 10, budgetedAmount: 400);
    final budget = createTestBudget(id: 1, categories: [category]);

    when(mockBudgetService.getNotificationRules(1)).thenAnswer((_) async => [
      NotificationRule(id: 1, budgetCategoryId: 10, thresholdPct: 0.9, enabled: false),
    ]);
    when(mockBudgetService.getAllCategorySpending(1, any, any)).thenAnswer((_) async => {10: 380.0});
    when(mockBudgetService.getActiveBudget()).thenAnswer((_) async => budget);

    final alerts = await notifService.checkThresholds(1, DateTime(2026, 3, 1), DateTime(2026, 4, 1));
    expect(alerts, isEmpty);
  });

  test('does not alert when below threshold', () async {
    final category = createTestBudgetCategory(id: 10, budgetedAmount: 400);
    final budget = createTestBudget(id: 1, categories: [category]);

    when(mockBudgetService.getNotificationRules(1)).thenAnswer((_) async => [
      NotificationRule(id: 1, budgetCategoryId: 10, thresholdPct: 0.9),
    ]);
    when(mockBudgetService.getAllCategorySpending(1, any, any)).thenAnswer((_) async => {10: 200.0});
    when(mockBudgetService.getActiveBudget()).thenAnswer((_) async => budget);
    when(mockBudgetService.getPeriodForCategory(10, any)).thenAnswer((_) async => null);

    final alerts = await notifService.checkThresholds(1, DateTime(2026, 3, 1), DateTime(2026, 4, 1));
    expect(alerts, isEmpty);
  });
}
