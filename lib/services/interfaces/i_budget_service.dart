import 'package:plutus_fe_prototype/models/budget_model.dart';

abstract class IBudgetService {
  Stream<Budget?> get budgetStream;
  void setCurrentUser(int userId);
  Future<void> notifyBudgetUpdate();

  // Budget CRUD
  Future<Budget> createBudget({
    required String name,
    required BudgetMode mode,
    required BudgetPeriodType periodType,
    required String currencyCode,
    DateTime? periodStart,
  });
  Future<Budget?> getActiveBudget();
  Future<Budget> updateBudget(
    int budgetId, {
    String? name,
    BudgetMode? mode,
    BudgetPeriodType? periodType,
    String? currencyCode,
    DateTime? periodStart,
  });
  Future<void> deleteBudget(int budgetId);

  // Category CRUD
  Future<BudgetCategory> addCategory({
    required int budgetId,
    required String name,
    required List<String> accountPatterns,
    required double amount,
    String? icon,
  });
  Future<BudgetCategory> updateCategory(
    int categoryId, {
    String? name,
    List<String>? accountPatterns,
    double? budgetedAmount,
    bool? rolloverEnabled,
    RolloverBehavior? rolloverBehavior,
    String? icon,
  });
  Future<void> removeCategory(int categoryId);
  Future<void> reorderCategories(int budgetId, List<int> categoryIds);

  // Spending
  Future<Map<int, double>> getAllCategorySpending(
      int budgetId, DateTime periodStart, DateTime periodEnd);
  Future<List<UnbudgetedEntry>> getUnbudgetedSpending(
      int budgetId, DateTime periodStart, DateTime periodEnd);
  Future<List<SuggestedCategory>> suggestCategoriesFromAccounts();

  // Rollover
  Future<double> calculateRollover(int categoryId, DateTime periodEnd);
  Future<void> closePeriod(int budgetId, DateTime periodEnd);

  // Periods
  Future<BudgetPeriod?> getPeriodForCategory(int categoryId, DateTime date);

  // Projections
  double getProjectedSpending(
      double currentSpent, DateTime periodStart, DateTime periodEnd);

  // Notification rules
  Future<void> setNotificationRule(
      int categoryId, double thresholdPct, bool enabled);
  Future<List<NotificationRule>> getNotificationRules(int budgetId);

  Future<void> dispose();
}
