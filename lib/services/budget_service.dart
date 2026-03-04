import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../providers/settings_provider.dart';

class BudgetPreferences {
  final double yearlyBudget;
  final Map<int, double> monthlyBudgets; // month (1-12) -> budget
  final String currencyCode;

  BudgetPreferences({
    required this.yearlyBudget,
    required this.monthlyBudgets,
    required this.currencyCode,
  });

  Map<String, dynamic> toJson() => {
        'yearlyBudget': yearlyBudget,
        'monthlyBudgets': monthlyBudgets.map((k, v) => MapEntry(k.toString(), v)),
        'currencyCode': currencyCode,
      };

  factory BudgetPreferences.fromJson(Map<String, dynamic> json) {
    final monthlyBudgetsJson = json['monthlyBudgets'] as Map<String, dynamic>? ?? {};
    final monthlyBudgets = <int, double>{};
    monthlyBudgetsJson.forEach((key, value) {
      final month = int.tryParse(key);
      if (month != null && value is num) {
        monthlyBudgets[month] = value.toDouble();
      }
    });

    return BudgetPreferences(
      yearlyBudget: (json['yearlyBudget'] as num?)?.toDouble() ?? 0.0,
      monthlyBudgets: monthlyBudgets,
      currencyCode: json['currencyCode'] as String? ?? 'USD',
    );
  }
}

class CategoryBudgetPreferences {
  final Map<String, double> categoryBudgets; // category name -> budget amount
  final List<String> selectedCategories; // categories user wants to track
  final String currencyCode;

  CategoryBudgetPreferences({
    required this.categoryBudgets,
    required this.selectedCategories,
    required this.currencyCode,
  });

  Map<String, dynamic> toJson() => {
        'categoryBudgets': categoryBudgets.map((k, v) => MapEntry(k, v)),
        'selectedCategories': selectedCategories,
        'currencyCode': currencyCode,
      };

  factory CategoryBudgetPreferences.fromJson(Map<String, dynamic> json) {
    final categoryBudgetsJson = json['categoryBudgets'] as Map<String, dynamic>? ?? {};
    final categoryBudgets = <String, double>{};
    categoryBudgetsJson.forEach((key, value) {
      if (value is num) {
        categoryBudgets[key] = value.toDouble();
      }
    });

    final selectedCategoriesJson = json['selectedCategories'] as List<dynamic>? ?? [];

    return CategoryBudgetPreferences(
      categoryBudgets: categoryBudgets,
      selectedCategories: selectedCategoriesJson.map((e) => e.toString()).toList(),
      currencyCode: json['currencyCode'] as String? ?? 'USD',
    );
  }
}

class BudgetService {
  static const String _budgetPrefsPrefix = 'budget_prefs_';
  static const String _categoryBudgetPrefsPrefix = 'category_budget_prefs_';

  /// Save budget preferences for a specific user
  Future<void> saveBudgetPreferences(
    int userId,
    BudgetPreferences preferences,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_budgetPrefsPrefix$userId';
    await prefs.setString(key, json.encode(preferences.toJson()));
  }

  /// Load budget preferences for a specific user
  Future<BudgetPreferences?> loadBudgetPreferences(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_budgetPrefsPrefix$userId';
    final data = prefs.getString(key);
    
    if (data == null) return null;
    
    try {
      final jsonData = json.decode(data) as Map<String, dynamic>;
      return BudgetPreferences.fromJson(jsonData);
    } catch (e) {
      return null;
    }
  }

  /// Clear budget preferences for a specific user
  Future<void> clearBudgetPreferences(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_budgetPrefsPrefix$userId';
    await prefs.remove(key);
  }

  /// Save category budget preferences for a specific user
  Future<void> saveCategoryBudgetPreferences(
    int userId,
    CategoryBudgetPreferences preferences,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_categoryBudgetPrefsPrefix$userId';
    await prefs.setString(key, json.encode(preferences.toJson()));
  }

  /// Load category budget preferences for a specific user
  Future<CategoryBudgetPreferences?> loadCategoryBudgetPreferences(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_categoryBudgetPrefsPrefix$userId';
    final data = prefs.getString(key);
    
    if (data == null) return null;
    
    try {
      final jsonData = json.decode(data) as Map<String, dynamic>;
      return CategoryBudgetPreferences.fromJson(jsonData);
    } catch (e) {
      return null;
    }
  }

  /// Clear category budget preferences for a specific user
  Future<void> clearCategoryBudgetPreferences(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_categoryBudgetPrefsPrefix$userId';
    await prefs.remove(key);
  }
}
