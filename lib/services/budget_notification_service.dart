import 'package:plutus_fe_prototype/models/budget_model.dart';
import 'package:plutus_fe_prototype/services/interfaces/i_budget_service.dart';

class BudgetAlert {
  final BudgetCategory category;
  final double spent;
  final double budgeted;
  final double thresholdPct;
  final String message;

  const BudgetAlert({
    required this.category,
    required this.spent,
    required this.budgeted,
    required this.thresholdPct,
    required this.message,
  });
}

class BudgetNotificationService {
  final IBudgetService _budgetService;

  BudgetNotificationService({required IBudgetService budgetService})
      : _budgetService = budgetService;

  Future<List<BudgetAlert>> checkThresholds(
    int budgetId,
    DateTime periodStart,
    DateTime periodEnd,
  ) async {
    final rules = await _budgetService.getNotificationRules(budgetId);
    if (rules.isEmpty) return [];

    final spending = await _budgetService.getAllCategorySpending(budgetId, periodStart, periodEnd);
    final budget = await _budgetService.getActiveBudget();
    if (budget == null) return [];

    final alerts = <BudgetAlert>[];
    for (final rule in rules) {
      if (!rule.enabled) continue;
      final category = budget.categories.where((c) => c.id == rule.budgetCategoryId).firstOrNull;
      if (category == null) continue;

      final period = await _budgetService.getPeriodForCategory(category.id!, periodStart);
      final effectiveBudget = period?.budgetedAmount ?? category.budgetedAmount;
      final spent = spending[category.id!] ?? 0;

      if (effectiveBudget > 0 && spent / effectiveBudget >= rule.thresholdPct) {
        final pct = (spent / effectiveBudget * 100).round();
        alerts.add(BudgetAlert(
          category: category,
          spent: spent,
          budgeted: effectiveBudget,
          thresholdPct: rule.thresholdPct,
          message: '${category.name} is at $pct% of budget (\$${spent.toStringAsFixed(0)} / \$${effectiveBudget.toStringAsFixed(0)})',
        ));
      }
    }
    return alerts;
  }
}
