import 'dart:convert';

import 'package:equatable/equatable.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum BudgetMode {
  spendingLimit,
  zeroBased;

  String toDbString() {
    switch (this) {
      case BudgetMode.spendingLimit:
        return 'spending_limit';
      case BudgetMode.zeroBased:
        return 'zero_based';
    }
  }

  static BudgetMode fromDbString(String? value) {
    switch (value) {
      case 'spending_limit':
        return BudgetMode.spendingLimit;
      case 'zero_based':
        return BudgetMode.zeroBased;
      default:
        return BudgetMode.spendingLimit;
    }
  }
}

enum BudgetPeriodType {
  monthly,
  weekly,
  biweekly;

  String toDbString() => name;

  static BudgetPeriodType fromDbString(String? value) {
    return BudgetPeriodType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BudgetPeriodType.monthly,
    );
  }
}

enum RolloverBehavior {
  carry,
  reset;

  String toDbString() => name;

  static RolloverBehavior fromDbString(String? value) {
    return RolloverBehavior.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RolloverBehavior.carry,
    );
  }
}

enum BudgetStatus {
  onTrack,
  warning,
  overBudget;

  static BudgetStatus fromPercentage(double percentage) {
    if (percentage >= 0.9) return BudgetStatus.overBudget;
    if (percentage >= 0.7) return BudgetStatus.warning;
    return BudgetStatus.onTrack;
  }
}

// ---------------------------------------------------------------------------
// Budget
// ---------------------------------------------------------------------------

class Budget extends Equatable {
  final int? id;
  final int userId;
  final String name;
  final BudgetMode mode;
  final BudgetPeriodType periodType;
  final DateTime? periodStart;
  final String currencyCode;
  final bool isActive;
  final List<BudgetCategory> categories;

  const Budget({
    this.id,
    required this.userId,
    required this.name,
    required this.mode,
    required this.periodType,
    this.periodStart,
    required this.currencyCode,
    this.isActive = true,
    this.categories = const [],
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        mode,
        periodType,
        periodStart,
        currencyCode,
        isActive,
        categories,
      ];

  Map<String, dynamic> toMap() {
    final now = DateTime.now();
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'mode': mode.toDbString(),
      'period_type': periodType.toDbString(),
      'period_start': periodStart?.toIso8601String(),
      'currency_code': currencyCode,
      'is_active': isActive ? 1 : 0,
      'created_at': now.millisecondsSinceEpoch,
      'updated_at': now.millisecondsSinceEpoch,
    };
  }

  factory Budget.fromMap(
    Map<String, dynamic> map, {
    List<BudgetCategory> categories = const [],
  }) {
    return Budget(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      name: map['name'] as String,
      mode: BudgetMode.fromDbString(map['mode'] as String?),
      periodType: BudgetPeriodType.fromDbString(map['period_type'] as String?),
      periodStart: map['period_start'] != null
          ? DateTime.parse(map['period_start'] as String)
          : null,
      currencyCode: map['currency_code'] as String,
      isActive: (map['is_active'] as int) == 1,
      categories: categories,
    );
  }

  Budget copyWith({
    int? id,
    int? userId,
    String? name,
    BudgetMode? mode,
    BudgetPeriodType? periodType,
    DateTime? periodStart,
    String? currencyCode,
    bool? isActive,
    List<BudgetCategory>? categories,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      mode: mode ?? this.mode,
      periodType: periodType ?? this.periodType,
      periodStart: periodStart ?? this.periodStart,
      currencyCode: currencyCode ?? this.currencyCode,
      isActive: isActive ?? this.isActive,
      categories: categories ?? this.categories,
    );
  }
}

// ---------------------------------------------------------------------------
// BudgetCategory
// ---------------------------------------------------------------------------

class BudgetCategory extends Equatable {
  final int? id;
  final int budgetId;
  final String name;
  final List<String> accountPatterns;
  final double budgetedAmount;
  final bool rolloverEnabled;
  final RolloverBehavior rolloverBehavior;
  final int sortOrder;
  final String? icon;

  const BudgetCategory({
    this.id,
    required this.budgetId,
    required this.name,
    required this.accountPatterns,
    required this.budgetedAmount,
    this.rolloverEnabled = false,
    this.rolloverBehavior = RolloverBehavior.carry,
    this.sortOrder = 0,
    this.icon,
  });

  @override
  List<Object?> get props => [
        id,
        budgetId,
        name,
        accountPatterns,
        budgetedAmount,
        rolloverEnabled,
        rolloverBehavior,
        sortOrder,
        icon,
      ];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'budget_id': budgetId,
      'name': name,
      'account_patterns': jsonEncode(accountPatterns),
      'budgeted_amount': budgetedAmount,
      'rollover_enabled': rolloverEnabled ? 1 : 0,
      'rollover_behavior': rolloverBehavior.toDbString(),
      'sort_order': sortOrder,
      'icon': icon,
    };
  }

  factory BudgetCategory.fromMap(Map<String, dynamic> map) {
    final rawPatterns = jsonDecode(map['account_patterns'] as String) as List;
    return BudgetCategory(
      id: map['id'] as int?,
      budgetId: map['budget_id'] as int,
      name: map['name'] as String,
      accountPatterns: rawPatterns.cast<String>(),
      budgetedAmount: (map['budgeted_amount'] as num).toDouble(),
      rolloverEnabled: (map['rollover_enabled'] as int) == 1,
      rolloverBehavior:
          RolloverBehavior.fromDbString(map['rollover_behavior'] as String?),
      sortOrder: map['sort_order'] as int? ?? 0,
      icon: map['icon'] as String?,
    );
  }

  BudgetCategory copyWith({
    int? id,
    int? budgetId,
    String? name,
    List<String>? accountPatterns,
    double? budgetedAmount,
    bool? rolloverEnabled,
    RolloverBehavior? rolloverBehavior,
    int? sortOrder,
    String? icon,
  }) {
    return BudgetCategory(
      id: id ?? this.id,
      budgetId: budgetId ?? this.budgetId,
      name: name ?? this.name,
      accountPatterns: accountPatterns ?? this.accountPatterns,
      budgetedAmount: budgetedAmount ?? this.budgetedAmount,
      rolloverEnabled: rolloverEnabled ?? this.rolloverEnabled,
      rolloverBehavior: rolloverBehavior ?? this.rolloverBehavior,
      sortOrder: sortOrder ?? this.sortOrder,
      icon: icon ?? this.icon,
    );
  }

  /// Returns true if [accountName] matches any of the stored patterns using
  /// case-insensitive prefix matching.
  bool matchesAccount(String accountName) {
    final lowerAccount = accountName.toLowerCase();
    return accountPatterns.any(
      (pattern) => lowerAccount.startsWith(pattern.toLowerCase()),
    );
  }
}

// ---------------------------------------------------------------------------
// BudgetPeriod
// ---------------------------------------------------------------------------

class BudgetPeriod extends Equatable {
  final int? id;
  final int budgetCategoryId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double budgetedAmount;
  final double rolloverAmount;

  const BudgetPeriod({
    this.id,
    required this.budgetCategoryId,
    required this.periodStart,
    required this.periodEnd,
    required this.budgetedAmount,
    this.rolloverAmount = 0,
  });

  @override
  List<Object?> get props => [
        id,
        budgetCategoryId,
        periodStart,
        periodEnd,
        budgetedAmount,
        rolloverAmount,
      ];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'budget_category_id': budgetCategoryId,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'budgeted_amount': budgetedAmount,
      'rollover_amount': rolloverAmount,
    };
  }

  factory BudgetPeriod.fromMap(Map<String, dynamic> map) {
    return BudgetPeriod(
      id: map['id'] as int?,
      budgetCategoryId: map['budget_category_id'] as int,
      periodStart: DateTime.parse(map['period_start'] as String),
      periodEnd: DateTime.parse(map['period_end'] as String),
      budgetedAmount: (map['budgeted_amount'] as num).toDouble(),
      rolloverAmount: (map['rollover_amount'] as num?)?.toDouble() ?? 0,
    );
  }

  BudgetPeriod copyWith({
    int? id,
    int? budgetCategoryId,
    DateTime? periodStart,
    DateTime? periodEnd,
    double? budgetedAmount,
    double? rolloverAmount,
  }) {
    return BudgetPeriod(
      id: id ?? this.id,
      budgetCategoryId: budgetCategoryId ?? this.budgetCategoryId,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      budgetedAmount: budgetedAmount ?? this.budgetedAmount,
      rolloverAmount: rolloverAmount ?? this.rolloverAmount,
    );
  }
}

// ---------------------------------------------------------------------------
// NotificationRule
// ---------------------------------------------------------------------------

class NotificationRule extends Equatable {
  final int? id;
  final int budgetCategoryId;
  final double thresholdPct;
  final bool enabled;

  const NotificationRule({
    this.id,
    required this.budgetCategoryId,
    required this.thresholdPct,
    this.enabled = true,
  });

  @override
  List<Object?> get props => [id, budgetCategoryId, thresholdPct, enabled];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'budget_category_id': budgetCategoryId,
      'threshold_pct': thresholdPct,
      'enabled': enabled ? 1 : 0,
    };
  }

  factory NotificationRule.fromMap(Map<String, dynamic> map) {
    return NotificationRule(
      id: map['id'] as int?,
      budgetCategoryId: map['budget_category_id'] as int,
      thresholdPct: (map['threshold_pct'] as num).toDouble(),
      enabled: (map['enabled'] as int) == 1,
    );
  }

  NotificationRule copyWith({
    int? id,
    int? budgetCategoryId,
    double? thresholdPct,
    bool? enabled,
  }) {
    return NotificationRule(
      id: id ?? this.id,
      budgetCategoryId: budgetCategoryId ?? this.budgetCategoryId,
      thresholdPct: thresholdPct ?? this.thresholdPct,
      enabled: enabled ?? this.enabled,
    );
  }
}

// ---------------------------------------------------------------------------
// Computed / view-only classes (no persistence)
// ---------------------------------------------------------------------------

class CategorySpending {
  final BudgetCategory category;
  final BudgetPeriod? period;
  final double spent;
  final double budgetedAmount;
  final double remaining;
  final double projectedSpending;
  final BudgetStatus status;

  const CategorySpending({
    required this.category,
    this.period,
    required this.spent,
    required this.budgetedAmount,
    required this.remaining,
    required this.projectedSpending,
    required this.status,
  });
}

class UnbudgetedEntry extends Equatable {
  final String accountName;
  final double spent;
  final String suggestedCategoryName;

  const UnbudgetedEntry({
    required this.accountName,
    required this.spent,
    required this.suggestedCategoryName,
  });

  @override
  List<Object?> get props => [accountName, spent, suggestedCategoryName];
}

class SuggestedCategory extends Equatable {
  final String accountName;
  final String suggestedName;
  final double recentSpending;

  const SuggestedCategory({
    required this.accountName,
    required this.suggestedName,
    required this.recentSpending,
  });

  @override
  List<Object?> get props => [accountName, suggestedName, recentSpending];
}
