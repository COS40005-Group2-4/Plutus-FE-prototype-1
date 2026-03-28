import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plutus_fe_prototype/models/budget_model.dart';
import 'package:plutus_fe_prototype/services/budget_migration_service.dart';
import '../helpers/mock_services.mocks.dart';
import '../helpers/test_fixtures.dart';

void main() {
  late MockIBudgetService mockBudgetService;
  late BudgetMigrationService migrationService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockBudgetService = MockIBudgetService();
    migrationService = BudgetMigrationService(budgetService: mockBudgetService);
  });

  test('hasLegacyData returns false when no data exists', () async {
    expect(await migrationService.hasLegacyData(1), false);
  });

  test('hasLegacyData returns true when old budget prefs exist', () async {
    SharedPreferences.setMockInitialValues({
      'budget_prefs_1': '{"yearlyBudget":5000,"currencyCode":"USD"}',
    });
    migrationService = BudgetMigrationService(budgetService: mockBudgetService);
    expect(await migrationService.hasLegacyData(1), true);
  });

  test('migrateFromSharedPreferences creates budget and categories', () async {
    SharedPreferences.setMockInitialValues({
      'budget_prefs_1':
          '{"yearlyBudget":5000,"monthlyBudgets":{},"currencyCode":"USD"}',
      'category_budget_prefs_1':
          '{"categoryBudgets":{"Food":400,"Transportation":300},"selectedCategories":["Food","Transportation"],"currencyCode":"USD"}',
    });
    migrationService = BudgetMigrationService(budgetService: mockBudgetService);

    final testBudget = createTestBudget(id: 1);
    when(mockBudgetService.createBudget(
      name: anyNamed('name'),
      mode: anyNamed('mode'),
      periodType: anyNamed('periodType'),
      currencyCode: anyNamed('currencyCode'),
    )).thenAnswer((_) async => testBudget);
    when(mockBudgetService.addCategory(
      budgetId: anyNamed('budgetId'),
      name: anyNamed('name'),
      accountPatterns: anyNamed('accountPatterns'),
      amount: anyNamed('amount'),
      icon: anyNamed('icon'),
    )).thenAnswer((_) async => createTestBudgetCategory());

    final result = await migrationService.migrateFromSharedPreferences(1);
    expect(result, true);
    verify(mockBudgetService.createBudget(
      name: 'My Budget',
      mode: BudgetMode.spendingLimit,
      periodType: BudgetPeriodType.monthly,
      currencyCode: 'USD',
    )).called(1);
    // Verify categories were added (Food with icon 🍔, Transportation with icon 🚗)
    verify(mockBudgetService.addCategory(
      budgetId: 1,
      name: 'Food',
      accountPatterns: ['Expenses:Food'],
      amount: 400.0,
      icon: '🍔',
    )).called(1);
    verify(mockBudgetService.addCategory(
      budgetId: 1,
      name: 'Transportation',
      accountPatterns: ['Expenses:Transportation'],
      amount: 300.0,
      icon: '🚗',
    )).called(1);

    // Verify old keys cleared
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('budget_prefs_1'), false);
    expect(prefs.containsKey('category_budget_prefs_1'), false);
  });

  test('migrateFromSharedPreferences returns false with no legacy data',
      () async {
    final result = await migrationService.migrateFromSharedPreferences(1);
    expect(result, false);
  });
}
