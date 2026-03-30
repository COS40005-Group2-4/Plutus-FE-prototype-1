import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plutus_fe_prototype/models/budget_model.dart';
import 'package:plutus_fe_prototype/services/interfaces/i_budget_service.dart';

class BudgetMigrationService {
  final IBudgetService _budgetService;
  static const String _budgetPrefsPrefix = 'budget_prefs_';
  static const String _categoryBudgetPrefsPrefix = 'category_budget_prefs_';

  BudgetMigrationService({required IBudgetService budgetService})
      : _budgetService = budgetService;

  Future<bool> hasLegacyData(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('$_budgetPrefsPrefix$userId') ||
        prefs.containsKey('$_categoryBudgetPrefsPrefix$userId');
  }

  Future<bool> migrateFromSharedPreferences(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final budgetJson = prefs.getString('$_budgetPrefsPrefix$userId');
    final categoryJson = prefs.getString('$_categoryBudgetPrefsPrefix$userId');
    if (budgetJson == null && categoryJson == null) return false;

    try {
      String currencyCode = 'USD';
      if (budgetJson != null) {
        final data = jsonDecode(budgetJson) as Map<String, dynamic>;
        currencyCode = data['currencyCode'] as String? ?? 'USD';
      }

      final budget = await _budgetService.createBudget(
        name: 'My Budget',
        mode: BudgetMode.spendingLimit,
        periodType: BudgetPeriodType.monthly,
        currencyCode: currencyCode,
      );

      if (categoryJson != null) {
        final data = jsonDecode(categoryJson) as Map<String, dynamic>;
        final categoryBudgets =
            (data['categoryBudgets'] as Map<String, dynamic>?) ?? {};
        final selectedCategories =
            (data['selectedCategories'] as List<dynamic>?)?.cast<String>() ??
                [];

        for (final categoryName in selectedCategories) {
          final amount =
              (categoryBudgets[categoryName] as num?)?.toDouble() ?? 0;
          if (amount > 0) {
            await _budgetService.addCategory(
              budgetId: budget.id!,
              name: categoryName,
              accountPatterns: ['Expenses:$categoryName'],
              amount: amount,
              icon: _guessIcon(categoryName),
            );
          }
        }
      }

      await prefs.remove('$_budgetPrefsPrefix$userId');
      await prefs.remove('$_categoryBudgetPrefsPrefix$userId');
      if (kDebugMode) debugPrint('Budget migration complete for user $userId');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Budget migration failed: $e');
      return false;
    }
  }

  String? _guessIcon(String categoryName) {
    final lower = categoryName.toLowerCase();
    if (lower.contains('food') || lower.contains('dining')) return '🍔';
    if (lower.contains('transport')) return '🚗';
    if (lower.contains('entertainment')) return '🎮';
    if (lower.contains('shopping')) return '🛒';
    if (lower.contains('bill')) return '📄';
    if (lower.contains('health')) return '🏥';
    if (lower.contains('education')) return '📚';
    if (lower.contains('housing') || lower.contains('rent')) return '🏠';
    return null;
  }
}
