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

class BudgetService {
  static const String _budgetPrefsPrefix = 'budget_prefs_';

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
}
