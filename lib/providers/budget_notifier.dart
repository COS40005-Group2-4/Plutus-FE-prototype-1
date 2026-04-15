import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/service_locator.dart';
import '../models/budget_model.dart';
import '../services/budget_notification_service.dart';
import '../services/interfaces/i_budget_service.dart';
import '../services/interfaces/i_transaction_service.dart';

// ---------------------------------------------------------------------------
// BudgetState
// ---------------------------------------------------------------------------

class BudgetState {
  final Budget? activeBudget;
  final List<CategorySpending> categorySpending;
  final List<UnbudgetedEntry> unbudgetedSpending;
  final List<BudgetAlert> alerts;
  final DateTime currentPeriodStart;
  final DateTime currentPeriodEnd;

  const BudgetState({
    required this.activeBudget,
    required this.categorySpending,
    required this.unbudgetedSpending,
    required this.alerts,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
  });

  factory BudgetState.empty() {
    final now = DateTime.now();
    return BudgetState(
      activeBudget: null,
      categorySpending: const [],
      unbudgetedSpending: const [],
      alerts: const [],
      currentPeriodStart: DateTime(now.year, now.month, 1),
      currentPeriodEnd: DateTime(now.year, now.month + 1, 1),
    );
  }

  BudgetState copyWith({
    Budget? activeBudget,
    bool clearBudget = false,
    List<CategorySpending>? categorySpending,
    List<UnbudgetedEntry>? unbudgetedSpending,
    List<BudgetAlert>? alerts,
    DateTime? currentPeriodStart,
    DateTime? currentPeriodEnd,
  }) {
    return BudgetState(
      activeBudget: clearBudget ? null : (activeBudget ?? this.activeBudget),
      categorySpending: categorySpending ?? this.categorySpending,
      unbudgetedSpending: unbudgetedSpending ?? this.unbudgetedSpending,
      alerts: alerts ?? this.alerts,
      currentPeriodStart: currentPeriodStart ?? this.currentPeriodStart,
      currentPeriodEnd: currentPeriodEnd ?? this.currentPeriodEnd,
    );
  }

  // Computed getters
  double get totalBudgeted =>
      categorySpending.fold(0.0, (double sum, CategorySpending cs) => sum + cs.budgetedAmount);

  double get totalSpent =>
      categorySpending.fold(0.0, (double sum, CategorySpending cs) => sum + cs.spent);

  double get totalRemaining => totalBudgeted - totalSpent;

  double get overallProgress {
    final double budgeted = totalBudgeted;
    if (budgeted <= 0) return 0.0;
    return (totalSpent / budgeted).clamp(0.0, 1.5);
  }

  int get overBudgetCount =>
      categorySpending.where((CategorySpending cs) => cs.status == BudgetStatus.overBudget).length;

  int get warningCount =>
      categorySpending.where((CategorySpending cs) => cs.status == BudgetStatus.warning).length;
}

// ---------------------------------------------------------------------------
// BudgetNotifier
// ---------------------------------------------------------------------------

class BudgetNotifier extends AsyncNotifier<BudgetState> {
  late final IBudgetService _budgetService;
  late final ITransactionService _transactionService;
  late final BudgetNotificationService _notificationService;

  StreamSubscription<Budget?>? _budgetSubscription;
  StreamSubscription<dynamic>? _transactionSubscription;

  @override
  Future<BudgetState> build() async {
    _budgetService = sl<IBudgetService>();
    _transactionService = sl<ITransactionService>();
    _notificationService = sl<BudgetNotificationService>();

    _budgetSubscription = _budgetService.budgetStream.listen((_) {
      ref.invalidateSelf();
    });

    _transactionSubscription = _transactionService.transactionStream.listen((_) {
      ref.invalidateSelf();
    });

    ref.onDispose(() {
      _budgetSubscription?.cancel();
      _transactionSubscription?.cancel();
    });

    return _loadBudget();
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  void setCurrentUser(int userId) {
    _budgetService.setCurrentUser(userId);
  }

  Future<void> navigatePeriod(int direction) async {
    final AsyncData<BudgetState>? current = state.asData;
    if (current == null) return;

    final BudgetState currentState = current.value;
    final Budget? budget = currentState.activeBudget;
    if (budget == null) return;

    DateTime newStart = currentState.currentPeriodStart;
    DateTime newEnd = currentState.currentPeriodEnd;

    switch (budget.periodType) {
      case BudgetPeriodType.monthly:
        newStart = DateTime(newStart.year, newStart.month + direction, 1);
        newEnd = DateTime(newEnd.year, newEnd.month + direction, 1);
        break;
      case BudgetPeriodType.weekly:
        newStart = newStart.add(Duration(days: 7 * direction));
        newEnd = newEnd.add(Duration(days: 7 * direction));
        break;
      case BudgetPeriodType.biweekly:
        newStart = newStart.add(Duration(days: 14 * direction));
        newEnd = newEnd.add(Duration(days: 14 * direction));
        break;
    }

    // Update state with new period bounds, then recompute spending
    state = AsyncData(currentState.copyWith(
      currentPeriodStart: newStart,
      currentPeriodEnd: newEnd,
    ));

    await _refreshSpendingWithState(newStart, newEnd);
  }

  Future<void> quickUpdateAmount(int categoryId, double newAmount) async {
    await _budgetService.updateCategory(categoryId, budgetedAmount: newAmount);
    ref.invalidateSelf();
  }

  Future<void> refreshSpending() async {
    ref.invalidateSelf();
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  Future<BudgetState> _loadBudget() async {
    final Budget? budget = await _budgetService.getActiveBudget();

    if (budget == null) {
      return BudgetState.empty();
    }

    final BudgetState periodState = _computePeriodBounds(budget);

    final List<CategorySpending> categorySpending = await _computeSpending(
      budget,
      periodState.currentPeriodStart,
      periodState.currentPeriodEnd,
    );

    final List<UnbudgetedEntry> unbudgetedSpending =
        await _budgetService.getUnbudgetedSpending(
      budget.id!,
      periodState.currentPeriodStart,
      periodState.currentPeriodEnd,
    );

    final List<BudgetAlert> alerts = await _notificationService.checkThresholds(
      budget.id!,
      periodState.currentPeriodStart,
      periodState.currentPeriodEnd,
    );

    return BudgetState(
      activeBudget: budget,
      categorySpending: categorySpending,
      unbudgetedSpending: unbudgetedSpending,
      alerts: alerts,
      currentPeriodStart: periodState.currentPeriodStart,
      currentPeriodEnd: periodState.currentPeriodEnd,
    );
  }

  BudgetState _computePeriodBounds(Budget budget) {
    final DateTime now = DateTime.now();
    DateTime periodStart;
    DateTime periodEnd;

    switch (budget.periodType) {
      case BudgetPeriodType.monthly:
        periodStart = DateTime(now.year, now.month, 1);
        periodEnd = DateTime(now.year, now.month + 1, 1);
        break;
      case BudgetPeriodType.weekly:
        final int daysFromMonday = now.weekday - 1;
        periodStart = DateTime(now.year, now.month, now.day - daysFromMonday);
        periodEnd = periodStart.add(const Duration(days: 7));
        break;
      case BudgetPeriodType.biweekly:
        final DateTime anchor =
            budget.periodStart ?? DateTime(now.year, now.month, 1);
        final int daysDiff = now.difference(anchor).inDays;
        final int periodsElapsed = (daysDiff / 14).floor();
        periodStart = anchor.add(Duration(days: periodsElapsed * 14));
        periodEnd = periodStart.add(const Duration(days: 14));
        break;
    }

    return BudgetState.empty().copyWith(
      currentPeriodStart: periodStart,
      currentPeriodEnd: periodEnd,
    );
  }

  Future<void> _refreshSpendingWithState(
    DateTime periodStart,
    DateTime periodEnd,
  ) async {
    final AsyncData<BudgetState>? current = state.asData;
    if (current == null) return;

    final BudgetState currentState = current.value;
    final Budget? budget = currentState.activeBudget;
    if (budget == null) return;

    state = const AsyncLoading<BudgetState>().copyWithPrevious(state);

    try {
      final List<CategorySpending> categorySpending =
          await _computeSpending(budget, periodStart, periodEnd);

      final List<UnbudgetedEntry> unbudgetedSpending =
          await _budgetService.getUnbudgetedSpending(
        budget.id!,
        periodStart,
        periodEnd,
      );

      final List<BudgetAlert> alerts =
          await _notificationService.checkThresholds(
        budget.id!,
        periodStart,
        periodEnd,
      );

      state = AsyncData(currentState.copyWith(
        categorySpending: categorySpending,
        unbudgetedSpending: unbudgetedSpending,
        alerts: alerts,
        currentPeriodStart: periodStart,
        currentPeriodEnd: periodEnd,
      ));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<List<CategorySpending>> _computeSpending(
    Budget budget,
    DateTime periodStart,
    DateTime periodEnd,
  ) async {
    // 1. Get all category spending map from service
    final Map<int, double> spendingMap =
        await _budgetService.getAllCategorySpending(
      budget.id!,
      periodStart,
      periodEnd,
    );

    // 2. Build CategorySpending list for each category
    final List<CategorySpending> spendingList = <CategorySpending>[];
    for (final BudgetCategory category in budget.categories) {
      final int categoryId = category.id!;
      final double spent = spendingMap[categoryId] ?? 0.0;

      // Get period record
      final BudgetPeriod? period = await _budgetService.getPeriodForCategory(
        categoryId,
        periodStart,
      );

      // Compute effective budget (period override or category default)
      final double effectiveBudget =
          period?.budgetedAmount ?? category.budgetedAmount;
      final double remaining = effectiveBudget - spent;

      // Projected spending
      final double projected = _budgetService.getProjectedSpending(
        spent,
        periodStart,
        periodEnd,
      );

      // Status based on percentage of budget used
      final double percentage =
          effectiveBudget > 0 ? spent / effectiveBudget : 0.0;
      final BudgetStatus status = BudgetStatus.fromPercentage(percentage);

      spendingList.add(CategorySpending(
        category: category,
        period: period,
        spent: spent,
        budgetedAmount: effectiveBudget,
        remaining: remaining,
        projectedSpending: projected,
        status: status,
      ));
    }

    return spendingList;
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final AsyncNotifierProvider<BudgetNotifier, BudgetState> budgetNotifierProvider =
    AsyncNotifierProvider<BudgetNotifier, BudgetState>(BudgetNotifier.new);
