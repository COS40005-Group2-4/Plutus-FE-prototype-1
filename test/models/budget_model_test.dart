import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/models/budget_model.dart';

void main() {
  // -------------------------------------------------------------------------
  // Enum tests
  // -------------------------------------------------------------------------

  group('BudgetMode', () {
    test('toDbString returns correct strings', () {
      expect(BudgetMode.spendingLimit.toDbString(), 'spending_limit');
      expect(BudgetMode.zeroBased.toDbString(), 'zero_based');
    });

    test('fromDbString round-trips correctly', () {
      expect(BudgetMode.fromDbString('spending_limit'), BudgetMode.spendingLimit);
      expect(BudgetMode.fromDbString('zero_based'), BudgetMode.zeroBased);
    });

    test('fromDbString returns spendingLimit for unknown value', () {
      expect(BudgetMode.fromDbString('unknown'), BudgetMode.spendingLimit);
      expect(BudgetMode.fromDbString(null), BudgetMode.spendingLimit);
    });
  });

  group('BudgetPeriodType', () {
    test('toDbString uses enum name', () {
      expect(BudgetPeriodType.monthly.toDbString(), 'monthly');
      expect(BudgetPeriodType.weekly.toDbString(), 'weekly');
      expect(BudgetPeriodType.biweekly.toDbString(), 'biweekly');
    });

    test('fromDbString round-trips correctly', () {
      expect(BudgetPeriodType.fromDbString('monthly'), BudgetPeriodType.monthly);
      expect(BudgetPeriodType.fromDbString('weekly'), BudgetPeriodType.weekly);
      expect(BudgetPeriodType.fromDbString('biweekly'), BudgetPeriodType.biweekly);
    });

    test('fromDbString returns monthly for unknown value', () {
      expect(BudgetPeriodType.fromDbString('unknown'), BudgetPeriodType.monthly);
      expect(BudgetPeriodType.fromDbString(null), BudgetPeriodType.monthly);
    });
  });

  group('RolloverBehavior', () {
    test('toDbString uses enum name', () {
      expect(RolloverBehavior.carry.toDbString(), 'carry');
      expect(RolloverBehavior.reset.toDbString(), 'reset');
    });

    test('fromDbString round-trips correctly', () {
      expect(RolloverBehavior.fromDbString('carry'), RolloverBehavior.carry);
      expect(RolloverBehavior.fromDbString('reset'), RolloverBehavior.reset);
    });

    test('fromDbString returns carry for unknown value', () {
      expect(RolloverBehavior.fromDbString('unknown'), RolloverBehavior.carry);
      expect(RolloverBehavior.fromDbString(null), RolloverBehavior.carry);
    });
  });

  group('BudgetStatus', () {
    test('fromPercentage returns overBudget for >= 0.9', () {
      expect(BudgetStatus.fromPercentage(0.9), BudgetStatus.overBudget);
      expect(BudgetStatus.fromPercentage(1.0), BudgetStatus.overBudget);
      expect(BudgetStatus.fromPercentage(1.5), BudgetStatus.overBudget);
    });

    test('fromPercentage returns warning for >= 0.7 and < 0.9', () {
      expect(BudgetStatus.fromPercentage(0.7), BudgetStatus.warning);
      expect(BudgetStatus.fromPercentage(0.8), BudgetStatus.warning);
      expect(BudgetStatus.fromPercentage(0.89), BudgetStatus.warning);
    });

    test('fromPercentage returns onTrack for < 0.7', () {
      expect(BudgetStatus.fromPercentage(0.0), BudgetStatus.onTrack);
      expect(BudgetStatus.fromPercentage(0.5), BudgetStatus.onTrack);
      expect(BudgetStatus.fromPercentage(0.69), BudgetStatus.onTrack);
    });
  });

  // -------------------------------------------------------------------------
  // Budget
  // -------------------------------------------------------------------------

  group('Budget', () {
    Budget createBudget({
      int? id = 1,
      int userId = 42,
      String name = 'My Budget',
      BudgetMode mode = BudgetMode.spendingLimit,
      BudgetPeriodType periodType = BudgetPeriodType.monthly,
      DateTime? periodStart,
      String currencyCode = 'USD',
      bool isActive = true,
      List<BudgetCategory> categories = const [],
    }) {
      return Budget(
        id: id,
        userId: userId,
        name: name,
        mode: mode,
        periodType: periodType,
        periodStart: periodStart,
        currencyCode: currencyCode,
        isActive: isActive,
        categories: categories,
      );
    }

    group('toMap', () {
      test('serializes all fields correctly', () {
        final budget = createBudget(periodStart: DateTime(2024, 1, 1));
        final map = budget.toMap();

        expect(map['id'], 1);
        expect(map['user_id'], 42);
        expect(map['name'], 'My Budget');
        expect(map['mode'], 'spending_limit');
        expect(map['period_type'], 'monthly');
        expect(map['period_start'], '2024-01-01T00:00:00.000');
        expect(map['currency_code'], 'USD');
        expect(map['is_active'], 1);
        expect(map['created_at'], isA<int>());
        expect(map['updated_at'], isA<int>());
      });

      test('serializes is_active false as 0', () {
        final budget = createBudget(isActive: false);
        expect(budget.toMap()['is_active'], 0);
      });

      test('serializes null periodStart as null', () {
        final budget = createBudget(periodStart: null);
        expect(budget.toMap()['period_start'], isNull);
      });
    });

    group('fromMap', () {
      test('deserializes all fields correctly', () {
        final map = {
          'id': 1,
          'user_id': 42,
          'name': 'My Budget',
          'mode': 'spending_limit',
          'period_type': 'monthly',
          'period_start': '2024-01-01T00:00:00.000',
          'currency_code': 'USD',
          'is_active': 1,
        };

        final budget = Budget.fromMap(map);

        expect(budget.id, 1);
        expect(budget.userId, 42);
        expect(budget.name, 'My Budget');
        expect(budget.mode, BudgetMode.spendingLimit);
        expect(budget.periodType, BudgetPeriodType.monthly);
        expect(budget.periodStart, DateTime(2024, 1, 1));
        expect(budget.currencyCode, 'USD');
        expect(budget.isActive, true);
        expect(budget.categories, isEmpty);
      });

      test('deserializes is_active = 0 as false', () {
        final map = {
          'id': 1,
          'user_id': 1,
          'name': 'Budget',
          'mode': 'spending_limit',
          'period_type': 'monthly',
          'period_start': null,
          'currency_code': 'USD',
          'is_active': 0,
        };

        expect(Budget.fromMap(map).isActive, false);
      });

      test('accepts categories parameter', () {
        final category = BudgetCategory(
          budgetId: 1,
          name: 'Food',
          accountPatterns: const ['Food'],
          budgetedAmount: 500,
        );
        final map = {
          'id': 1,
          'user_id': 1,
          'name': 'Budget',
          'mode': 'spending_limit',
          'period_type': 'monthly',
          'period_start': null,
          'currency_code': 'USD',
          'is_active': 1,
        };

        final budget = Budget.fromMap(map, categories: [category]);
        expect(budget.categories, hasLength(1));
        expect(budget.categories.first.name, 'Food');
      });
    });

    group('toMap/fromMap round-trip', () {
      test('preserves all fields', () {
        final original = createBudget(
          periodStart: DateTime(2024, 6, 1),
          mode: BudgetMode.zeroBased,
          periodType: BudgetPeriodType.weekly,
          isActive: false,
        );
        final map = original.toMap();
        final restored = Budget.fromMap(map);

        expect(restored.id, original.id);
        expect(restored.userId, original.userId);
        expect(restored.name, original.name);
        expect(restored.mode, original.mode);
        expect(restored.periodType, original.periodType);
        expect(restored.periodStart, original.periodStart);
        expect(restored.currencyCode, original.currencyCode);
        expect(restored.isActive, original.isActive);
      });
    });

    group('copyWith', () {
      test('preserves all fields when no overrides given', () {
        final budget = createBudget();
        expect(budget.copyWith(), budget);
      });

      test('overrides only specified fields', () {
        final budget = createBudget();
        final updated = budget.copyWith(name: 'Updated', isActive: false);

        expect(updated.name, 'Updated');
        expect(updated.isActive, false);
        expect(updated.userId, budget.userId);
        expect(updated.currencyCode, budget.currencyCode);
      });
    });

    group('Equatable', () {
      test('identical budgets are equal', () {
        final b1 = createBudget();
        final b2 = createBudget();
        expect(b1, b2);
        expect(b1.hashCode, b2.hashCode);
      });

      test('budgets with different names are not equal', () {
        final b1 = createBudget(name: 'A');
        final b2 = createBudget(name: 'B');
        expect(b1, isNot(b2));
      });
    });
  });

  // -------------------------------------------------------------------------
  // BudgetCategory
  // -------------------------------------------------------------------------

  group('BudgetCategory', () {
    BudgetCategory createCategory({
      int? id = 1,
      int budgetId = 10,
      String name = 'Groceries',
      List<String> accountPatterns = const ['Food', 'Grocery'],
      double budgetedAmount = 1000,
      bool rolloverEnabled = false,
      RolloverBehavior rolloverBehavior = RolloverBehavior.carry,
      int sortOrder = 0,
      String? icon,
    }) {
      return BudgetCategory(
        id: id,
        budgetId: budgetId,
        name: name,
        accountPatterns: accountPatterns,
        budgetedAmount: budgetedAmount,
        rolloverEnabled: rolloverEnabled,
        rolloverBehavior: rolloverBehavior,
        sortOrder: sortOrder,
        icon: icon,
      );
    }

    group('toMap', () {
      test('serializes accountPatterns as JSON string', () {
        final category = createCategory(accountPatterns: ['Food', 'Grocery']);
        final map = category.toMap();
        final decoded = jsonDecode(map['account_patterns'] as String);
        expect(decoded, ['Food', 'Grocery']);
      });

      test('serializes rollover_enabled as int', () {
        expect(createCategory(rolloverEnabled: true).toMap()['rollover_enabled'], 1);
        expect(createCategory(rolloverEnabled: false).toMap()['rollover_enabled'], 0);
      });

      test('serializes rollover_behavior as string', () {
        expect(
          createCategory(rolloverBehavior: RolloverBehavior.reset).toMap()['rollover_behavior'],
          'reset',
        );
      });
    });

    group('fromMap', () {
      test('deserializes all fields correctly', () {
        final map = {
          'id': 1,
          'budget_id': 10,
          'name': 'Groceries',
          'account_patterns': jsonEncode(['Food', 'Grocery']),
          'budgeted_amount': 1000.0,
          'rollover_enabled': 0,
          'rollover_behavior': 'carry',
          'sort_order': 0,
          'icon': null,
        };

        final category = BudgetCategory.fromMap(map);

        expect(category.id, 1);
        expect(category.budgetId, 10);
        expect(category.name, 'Groceries');
        expect(category.accountPatterns, ['Food', 'Grocery']);
        expect(category.budgetedAmount, 1000.0);
        expect(category.rolloverEnabled, false);
        expect(category.rolloverBehavior, RolloverBehavior.carry);
        expect(category.sortOrder, 0);
        expect(category.icon, isNull);
      });

      test('deserializes rollover_enabled = 1 as true', () {
        final map = {
          'id': null,
          'budget_id': 1,
          'name': 'Cat',
          'account_patterns': jsonEncode([]),
          'budgeted_amount': 0.0,
          'rollover_enabled': 1,
          'rollover_behavior': 'carry',
          'sort_order': 0,
          'icon': null,
        };

        expect(BudgetCategory.fromMap(map).rolloverEnabled, true);
      });
    });

    group('toMap/fromMap round-trip', () {
      test('preserves all fields including JSON accountPatterns', () {
        final original = createCategory(
          accountPatterns: ['Supermarket', 'Market', 'Food Court'],
          rolloverEnabled: true,
          rolloverBehavior: RolloverBehavior.reset,
          sortOrder: 3,
          icon: 'shopping_cart',
        );
        final restored = BudgetCategory.fromMap(original.toMap());

        expect(restored.id, original.id);
        expect(restored.budgetId, original.budgetId);
        expect(restored.name, original.name);
        expect(restored.accountPatterns, original.accountPatterns);
        expect(restored.budgetedAmount, original.budgetedAmount);
        expect(restored.rolloverEnabled, original.rolloverEnabled);
        expect(restored.rolloverBehavior, original.rolloverBehavior);
        expect(restored.sortOrder, original.sortOrder);
        expect(restored.icon, original.icon);
      });
    });

    group('matchesAccount', () {
      test('returns true for exact match', () {
        final category = createCategory(accountPatterns: ['Food']);
        expect(category.matchesAccount('Food'), isTrue);
      });

      test('returns true for prefix match', () {
        final category = createCategory(accountPatterns: ['Food']);
        expect(category.matchesAccount('Food:Groceries'), isTrue);
      });

      test('is case-insensitive', () {
        final category = createCategory(accountPatterns: ['food']);
        expect(category.matchesAccount('FOOD:Groceries'), isTrue);
        expect(category.matchesAccount('Food'), isTrue);
      });

      test('returns false for non-matching account', () {
        final category = createCategory(accountPatterns: ['Food']);
        expect(category.matchesAccount('Entertainment'), isFalse);
      });

      test('returns false for empty pattern list', () {
        final category = createCategory(accountPatterns: []);
        expect(category.matchesAccount('Food'), isFalse);
      });

      test('matches against any pattern in the list', () {
        final category = createCategory(accountPatterns: ['Food', 'Grocery']);
        expect(category.matchesAccount('Grocery:Supermarket'), isTrue);
      });
    });

    group('copyWith', () {
      test('preserves all fields when no overrides given', () {
        final category = createCategory();
        expect(category.copyWith(), category);
      });

      test('overrides specified fields', () {
        final category = createCategory();
        final updated = category.copyWith(name: 'Dining', budgetedAmount: 2000);

        expect(updated.name, 'Dining');
        expect(updated.budgetedAmount, 2000);
        expect(updated.budgetId, category.budgetId);
      });
    });
  });

  // -------------------------------------------------------------------------
  // BudgetPeriod
  // -------------------------------------------------------------------------

  group('BudgetPeriod', () {
    final start = DateTime(2024, 1, 1);
    final end = DateTime(2024, 1, 31);

    BudgetPeriod createPeriod({
      int? id = 1,
      int budgetCategoryId = 5,
      DateTime? periodStart,
      DateTime? periodEnd,
      double budgetedAmount = 500,
      double rolloverAmount = 0,
    }) {
      return BudgetPeriod(
        id: id,
        budgetCategoryId: budgetCategoryId,
        periodStart: periodStart ?? start,
        periodEnd: periodEnd ?? end,
        budgetedAmount: budgetedAmount,
        rolloverAmount: rolloverAmount,
      );
    }

    group('toMap', () {
      test('serializes dates as ISO8601 strings', () {
        final period = createPeriod();
        final map = period.toMap();
        expect(map['period_start'], start.toIso8601String());
        expect(map['period_end'], end.toIso8601String());
      });
    });

    group('fromMap', () {
      test('deserializes all fields correctly', () {
        final map = {
          'id': 1,
          'budget_category_id': 5,
          'period_start': start.toIso8601String(),
          'period_end': end.toIso8601String(),
          'budgeted_amount': 500.0,
          'rollover_amount': 50.0,
        };

        final period = BudgetPeriod.fromMap(map);

        expect(period.id, 1);
        expect(period.budgetCategoryId, 5);
        expect(period.periodStart, start);
        expect(period.periodEnd, end);
        expect(period.budgetedAmount, 500.0);
        expect(period.rolloverAmount, 50.0);
      });

      test('defaults rolloverAmount to 0 when null', () {
        final map = {
          'id': 1,
          'budget_category_id': 5,
          'period_start': start.toIso8601String(),
          'period_end': end.toIso8601String(),
          'budgeted_amount': 500.0,
          'rollover_amount': null,
        };

        expect(BudgetPeriod.fromMap(map).rolloverAmount, 0.0);
      });
    });

    group('toMap/fromMap round-trip', () {
      test('preserves all fields', () {
        final original = createPeriod(rolloverAmount: 100.0);
        final restored = BudgetPeriod.fromMap(original.toMap());

        expect(restored.id, original.id);
        expect(restored.budgetCategoryId, original.budgetCategoryId);
        expect(restored.periodStart, original.periodStart);
        expect(restored.periodEnd, original.periodEnd);
        expect(restored.budgetedAmount, original.budgetedAmount);
        expect(restored.rolloverAmount, original.rolloverAmount);
      });
    });

    group('Equatable', () {
      test('identical periods are equal', () {
        final p1 = createPeriod();
        final p2 = createPeriod();
        expect(p1, p2);
      });

      test('periods with different amounts are not equal', () {
        final p1 = createPeriod(budgetedAmount: 100);
        final p2 = createPeriod(budgetedAmount: 200);
        expect(p1, isNot(p2));
      });
    });
  });

  // -------------------------------------------------------------------------
  // NotificationRule
  // -------------------------------------------------------------------------

  group('NotificationRule', () {
    NotificationRule createRule({
      int? id = 1,
      int budgetCategoryId = 5,
      double thresholdPct = 0.8,
      bool enabled = true,
    }) {
      return NotificationRule(
        id: id,
        budgetCategoryId: budgetCategoryId,
        thresholdPct: thresholdPct,
        enabled: enabled,
      );
    }

    group('toMap', () {
      test('serializes enabled as int 1', () {
        expect(createRule(enabled: true).toMap()['enabled'], 1);
      });

      test('serializes enabled as int 0', () {
        expect(createRule(enabled: false).toMap()['enabled'], 0);
      });
    });

    group('fromMap', () {
      test('deserializes all fields correctly', () {
        final map = {
          'id': 1,
          'budget_category_id': 5,
          'threshold_pct': 0.8,
          'enabled': 1,
        };

        final rule = NotificationRule.fromMap(map);

        expect(rule.id, 1);
        expect(rule.budgetCategoryId, 5);
        expect(rule.thresholdPct, 0.8);
        expect(rule.enabled, true);
      });

      test('deserializes enabled = 0 as false', () {
        final map = {
          'id': 1,
          'budget_category_id': 5,
          'threshold_pct': 0.8,
          'enabled': 0,
        };

        expect(NotificationRule.fromMap(map).enabled, false);
      });
    });

    group('toMap/fromMap round-trip', () {
      test('preserves all fields', () {
        final original = createRule(thresholdPct: 0.75, enabled: false);
        final restored = NotificationRule.fromMap(original.toMap());

        expect(restored.id, original.id);
        expect(restored.budgetCategoryId, original.budgetCategoryId);
        expect(restored.thresholdPct, original.thresholdPct);
        expect(restored.enabled, original.enabled);
      });
    });

    group('Equatable', () {
      test('identical rules are equal', () {
        expect(createRule(), createRule());
      });

      test('rules with different thresholds are not equal', () {
        expect(createRule(thresholdPct: 0.5), isNot(createRule(thresholdPct: 0.9)));
      });
    });
  });
}
