import 'dart:async';
import 'dart:convert';

import '../models/budget_model.dart';
import 'interfaces/i_budget_service.dart';
import 'interfaces/i_database_service.dart';

class BudgetService implements IBudgetService {
  final IDatabaseService _db;

  BudgetService({required IDatabaseService db}) : _db = db;

  int? _currentUserId;

  final StreamController<Budget?> _budgetStreamController =
      StreamController<Budget?>.broadcast();

  @override
  Stream<Budget?> get budgetStream => _budgetStreamController.stream;

  @override
  void setCurrentUser(int userId) {
    _currentUserId = userId;
  }

  @override
  Future<void> notifyBudgetUpdate() async {
    if (_currentUserId != null) {
      final budget = await getActiveBudget();
      if (!_budgetStreamController.isClosed) {
        _budgetStreamController.add(budget);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Budget CRUD
  // ---------------------------------------------------------------------------

  @override
  Future<Budget> createBudget({
    required String name,
    required BudgetMode mode,
    required BudgetPeriodType periodType,
    required String currencyCode,
    DateTime? periodStart,
  }) async {
    if (_currentUserId == null) {
      throw Exception('No user set');
    }

    // Deactivate any existing active budget for this user
    final existing = await _db.getActiveBudgetByUserId(_currentUserId!);
    if (existing != null && existing['id'] != null) {
      await _db.updateBudget(existing['id'] as int, {'is_active': 0});
    }

    final data = {
      'user_id': _currentUserId,
      'name': name,
      'mode': mode.toDbString(),
      'period_type': periodType.toDbString(),
      'period_start': periodStart?.toIso8601String(),
      'currency_code': currencyCode,
      'is_active': 1,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };

    final id = await _db.insertBudget(data);

    await notifyBudgetUpdate();

    return Budget(
      id: id,
      userId: _currentUserId!,
      name: name,
      mode: mode,
      periodType: periodType,
      periodStart: periodStart,
      currencyCode: currencyCode,
      isActive: true,
    );
  }

  @override
  Future<Budget?> getActiveBudget() async {
    if (_currentUserId == null) return null;

    final map = await _db.getActiveBudgetByUserId(_currentUserId!);
    if (map == null) return null;

    final budgetId = map['id'] as int;
    final categoryMaps =
        await _db.getBudgetCategoriesByBudgetId(budgetId);
    final categories =
        categoryMaps.map((m) => BudgetCategory.fromMap(m)).toList();

    return Budget.fromMap(map, categories: categories);
  }

  @override
  Future<Budget> updateBudget(
    int budgetId, {
    String? name,
    BudgetMode? mode,
    BudgetPeriodType? periodType,
    String? currencyCode,
    DateTime? periodStart,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };

    if (name != null) updates['name'] = name;
    if (mode != null) updates['mode'] = mode.toDbString();
    if (periodType != null) updates['period_type'] = periodType.toDbString();
    if (currencyCode != null) updates['currency_code'] = currencyCode;
    if (periodStart != null) updates['period_start'] = periodStart.toIso8601String();

    await _db.updateBudget(budgetId, updates);
    await notifyBudgetUpdate();

    final budget = await getActiveBudget();
    if (budget == null) {
      throw Exception('Budget not found after update');
    }
    return budget;
  }

  @override
  Future<void> deleteBudget(int budgetId) async {
    await _db.deleteBudgetCategoriesByBudgetId(budgetId);
    await _db.deleteBudget(budgetId);
    await notifyBudgetUpdate();
  }

  // ---------------------------------------------------------------------------
  // Category CRUD
  // ---------------------------------------------------------------------------

  @override
  Future<BudgetCategory> addCategory({
    required int budgetId,
    required String name,
    required List<String> accountPatterns,
    required double amount,
    String? icon,
  }) async {
    final existing = await _db.getBudgetCategoriesByBudgetId(budgetId);
    final maxOrder = existing.isEmpty
        ? -1
        : existing
            .map((m) => m['sort_order'] as int? ?? 0)
            .reduce((a, b) => a > b ? a : b);

    final now = DateTime.now().millisecondsSinceEpoch;
    final data = {
      'budget_id': budgetId,
      'name': name,
      'account_patterns': jsonEncode(accountPatterns),
      'budgeted_amount': amount,
      'rollover_enabled': 0,
      'rollover_behavior': RolloverBehavior.carry.toDbString(),
      'sort_order': maxOrder + 1,
      'icon': icon,
      'created_at': now,
      'updated_at': now,
    };

    final id = await _db.insertBudgetCategory(data);
    await notifyBudgetUpdate();

    return BudgetCategory(
      id: id,
      budgetId: budgetId,
      name: name,
      accountPatterns: accountPatterns,
      budgetedAmount: amount,
      sortOrder: maxOrder + 1,
      icon: icon,
    );
  }

  @override
  Future<BudgetCategory> updateCategory(
    int categoryId, {
    String? name,
    List<String>? accountPatterns,
    double? budgetedAmount,
    bool? rolloverEnabled,
    RolloverBehavior? rolloverBehavior,
    String? icon,
  }) async {
    final updates = <String, dynamic>{};

    if (name != null) updates['name'] = name;
    if (accountPatterns != null) {
      updates['account_patterns'] = jsonEncode(accountPatterns);
    }
    if (budgetedAmount != null) updates['budgeted_amount'] = budgetedAmount;
    if (rolloverEnabled != null) {
      updates['rollover_enabled'] = rolloverEnabled ? 1 : 0;
    }
    if (rolloverBehavior != null) {
      updates['rollover_behavior'] = rolloverBehavior.toDbString();
    }
    if (icon != null) updates['icon'] = icon;

    await _db.updateBudgetCategory(categoryId, updates);
    await notifyBudgetUpdate();

    final budget = await getActiveBudget();
    if (budget == null) {
      throw Exception('No active budget found');
    }

    final category = budget.categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => throw Exception('Category not found: $categoryId'),
    );

    return category;
  }

  @override
  Future<void> removeCategory(int categoryId) async {
    await _db.deleteBudgetPeriodsByCategoryId(categoryId);
    await _db.deleteNotificationRulesByCategoryId(categoryId);
    await _db.deleteBudgetCategory(categoryId);
    await notifyBudgetUpdate();
  }

  @override
  Future<void> reorderCategories(int budgetId, List<int> categoryIds) async {
    for (var i = 0; i < categoryIds.length; i++) {
      await _db.updateBudgetCategory(categoryIds[i], {'sort_order': i});
    }
    await notifyBudgetUpdate();
  }

  // ---------------------------------------------------------------------------
  // Spending
  // ---------------------------------------------------------------------------

  @override
  Future<Map<int, double>> getAllCategorySpending(
      int budgetId, DateTime periodStart, DateTime periodEnd) async {
    final categoryMaps = await _db.getBudgetCategoriesByBudgetId(budgetId);
    final categories =
        categoryMaps.map((m) => BudgetCategory.fromMap(m)).toList();

    if (_currentUserId == null) return {};

    final startTs = periodStart.toIso8601String();
    final endTs = periodEnd.toIso8601String();

    final postings = await _db.getExpensePostingsForPeriod(
        _currentUserId!, startTs, endTs);

    final result = <int, double>{};
    for (final category in categories) {
      if (category.id == null) continue;
      double total = 0;
      for (final posting in postings) {
        final account = posting['account'] as String? ?? '';
        if (category.matchesAccount(account)) {
          final amount = (posting['amount'] as num?)?.toDouble() ?? 0.0;
          total += amount;
        }
      }
      result[category.id!] = total;
    }

    return result;
  }

  @override
  Future<List<UnbudgetedEntry>> getUnbudgetedSpending(
      int budgetId, DateTime periodStart, DateTime periodEnd) async {
    final categoryMaps = await _db.getBudgetCategoriesByBudgetId(budgetId);
    final categories =
        categoryMaps.map((m) => BudgetCategory.fromMap(m)).toList();

    if (_currentUserId == null) return [];

    final startTs = periodStart.toIso8601String();
    final endTs = periodEnd.toIso8601String();

    final postings = await _db.getExpensePostingsForPeriod(
        _currentUserId!, startTs, endTs);

    // Group unmatched postings by account
    final unmatched = <String, double>{};
    for (final posting in postings) {
      final account = posting['account'] as String? ?? '';
      final matched =
          categories.any((c) => c.matchesAccount(account));
      if (!matched) {
        final amount = (posting['amount'] as num?)?.toDouble() ?? 0.0;
        unmatched[account] = (unmatched[account] ?? 0) + amount;
      }
    }

    // Convert to UnbudgetedEntry and sort by spent descending
    final entries = unmatched.entries.map((e) {
      final parts = e.key.split(':');
      final suggestedName = parts.length > 1 ? parts.last : e.key;
      return UnbudgetedEntry(
        accountName: e.key,
        spent: e.value,
        suggestedCategoryName: suggestedName,
      );
    }).toList();

    entries.sort((a, b) => b.spent.compareTo(a.spent));
    return entries;
  }

  @override
  Future<List<SuggestedCategory>> suggestCategoriesFromAccounts() async {
    if (_currentUserId == null) return [];

    final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
    final now = DateTime.now();

    final startTs = threeMonthsAgo.toIso8601String();
    final endTs = now.toIso8601String();

    final postings = await _db.getExpensePostingsForPeriod(
        _currentUserId!, startTs, endTs);

    // Get existing categories to filter out already-matched accounts
    final activeBudget = await getActiveBudget();
    final existingCategories = activeBudget?.categories ?? [];

    // Group by top-level expense account (first two segments)
    final accountSpending = <String, double>{};
    for (final posting in postings) {
      final account = posting['account'] as String? ?? '';
      final parts = account.split(':');
      final topLevel =
          parts.length >= 2 ? '${parts[0]}:${parts[1]}' : account;

      // Filter out accounts already covered by existing categories
      final alreadyCovered =
          existingCategories.any((c) => c.matchesAccount(account));
      if (!alreadyCovered) {
        final amount = (posting['amount'] as num?)?.toDouble() ?? 0.0;
        accountSpending[topLevel] = (accountSpending[topLevel] ?? 0) + amount;
      }
    }

    final suggestions = accountSpending.entries.map((e) {
      final parts = e.key.split(':');
      final suggestedName = parts.length > 1 ? parts[1] : e.key;
      return SuggestedCategory(
        accountName: e.key,
        suggestedName: suggestedName,
        recentSpending: e.value,
      );
    }).toList();

    suggestions.sort((a, b) => b.recentSpending.compareTo(a.recentSpending));
    return suggestions;
  }

  // ---------------------------------------------------------------------------
  // Rollover
  // ---------------------------------------------------------------------------

  @override
  Future<double> calculateRollover(int categoryId, DateTime periodEnd) async {
    final budget = await getActiveBudget();
    if (budget == null) return 0;

    BudgetCategory? category;
    try {
      category = budget.categories.firstWhere((c) => c.id == categoryId);
    } catch (_) {
      return 0;
    }

    if (!category.rolloverEnabled) return 0;

    // Find period start from DB or derive from periodEnd
    final period = await getPeriodForCategory(categoryId, periodEnd);
    final periodStart = period?.periodStart ??
        _getPeriodStart(periodEnd, budget.periodType, budget.periodStart);

    final spending = await getAllCategorySpending(
        budget.id!, periodStart, periodEnd);
    final spent = spending[categoryId] ?? 0;

    // Effective budget = base + any existing rollover for this period
    final effectiveBudget =
        category.budgetedAmount + (period?.rolloverAmount ?? 0);
    final remainder = effectiveBudget - spent;

    if (remainder < 0 &&
        category.rolloverBehavior == RolloverBehavior.reset) {
      return 0;
    }

    return remainder;
  }

  @override
  Future<void> closePeriod(int budgetId, DateTime periodEnd) async {
    final categoryMaps = await _db.getBudgetCategoriesByBudgetId(budgetId);
    final categories =
        categoryMaps.map((m) => BudgetCategory.fromMap(m)).toList();

    for (final category in categories) {
      if (category.id == null) continue;

      final budget = await getActiveBudget();
      if (budget == null) continue;

      final nextStart = _getNextPeriodEnd(
          periodEnd, budget.periodType, budget.periodStart);
      final nextEnd = _getNextPeriodEnd(
          nextStart, budget.periodType, budget.periodStart);

      // Check if next period already exists
      final existing =
          await _db.getBudgetPeriodForDate(category.id!, nextStart.toIso8601String());
      if (existing != null) continue;

      final rollover = await calculateRollover(category.id!, periodEnd);

      final periodData = BudgetPeriod(
        budgetCategoryId: category.id!,
        periodStart: nextStart,
        periodEnd: nextEnd,
        budgetedAmount: category.budgetedAmount,
        rolloverAmount: rollover,
      ).toMap();

      await _db.insertBudgetPeriod(periodData);
    }
  }

  // ---------------------------------------------------------------------------
  // Periods
  // ---------------------------------------------------------------------------

  @override
  Future<BudgetPeriod?> getPeriodForCategory(
      int categoryId, DateTime date) async {
    final map =
        await _db.getBudgetPeriodForDate(categoryId, date.toIso8601String());
    if (map == null) return null;
    return BudgetPeriod.fromMap(map);
  }

  // ---------------------------------------------------------------------------
  // Projections
  // ---------------------------------------------------------------------------

  @override
  double getProjectedSpending(
      double currentSpent, DateTime periodStart, DateTime periodEnd) {
    final now = DateTime.now();

    if (now.isBefore(periodStart) || now.isAfter(periodEnd)) {
      return currentSpent;
    }

    final elapsedDays = now.difference(periodStart).inSeconds / 86400.0;
    if (elapsedDays <= 0) return currentSpent;

    final totalDays =
        periodEnd.difference(periodStart).inSeconds / 86400.0;
    final dailyAverage = currentSpent / elapsedDays;

    return dailyAverage * totalDays;
  }

  // ---------------------------------------------------------------------------
  // Notification rules
  // ---------------------------------------------------------------------------

  @override
  Future<void> setNotificationRule(
      int categoryId, double thresholdPct, bool enabled) async {
    final existing =
        await _db.getNotificationRulesByCategoryId(categoryId);
    if (existing.isNotEmpty) {
      final ruleId = existing.first['id'] as int;
      await _db.updateNotificationRule(ruleId, {
        'threshold_pct': thresholdPct,
        'enabled': enabled ? 1 : 0,
      });
    } else {
      await _db.insertNotificationRule({
        'budget_category_id': categoryId,
        'threshold_pct': thresholdPct,
        'enabled': enabled ? 1 : 0,
      });
    }
  }

  @override
  Future<List<NotificationRule>> getNotificationRules(int budgetId) async {
    final categoryMaps = await _db.getBudgetCategoriesByBudgetId(budgetId);
    final rules = <NotificationRule>[];

    for (final catMap in categoryMaps) {
      final categoryId = catMap['id'] as int;
      final ruleMaps = await _db.getNotificationRulesByCategoryId(categoryId);
      rules.addAll(ruleMaps.map((m) => NotificationRule.fromMap(m)));
    }

    return rules;
  }

  // ---------------------------------------------------------------------------
  // Dispose
  // ---------------------------------------------------------------------------

  @override
  Future<void> dispose() async {
    // Singleton — do not close the stream
  }

  // ---------------------------------------------------------------------------
  // Private period helpers
  // ---------------------------------------------------------------------------

  DateTime _getPeriodStart(
      DateTime date, BudgetPeriodType periodType, DateTime? anchor) {
    switch (periodType) {
      case BudgetPeriodType.monthly:
        return DateTime(date.year, date.month, 1);
      case BudgetPeriodType.weekly:
        // Monday of the week
        final weekday = date.weekday; // 1 = Monday
        return DateTime(date.year, date.month, date.day - (weekday - 1));
      case BudgetPeriodType.biweekly:
        if (anchor == null) {
          return DateTime(date.year, date.month, date.day);
        }
        // Calculate how many 14-day cycles since anchor
        final daysSinceAnchor = date.difference(anchor).inDays;
        final cycleDay = daysSinceAnchor % 14;
        return date.subtract(Duration(days: cycleDay));
    }
  }

  DateTime _getNextPeriodEnd(
      DateTime periodStart, BudgetPeriodType periodType, DateTime? anchor) {
    switch (periodType) {
      case BudgetPeriodType.monthly:
        return DateTime(periodStart.year, periodStart.month + 1, 1);
      case BudgetPeriodType.weekly:
        return periodStart.add(const Duration(days: 7));
      case BudgetPeriodType.biweekly:
        return periodStart.add(const Duration(days: 14));
    }
  }
}
