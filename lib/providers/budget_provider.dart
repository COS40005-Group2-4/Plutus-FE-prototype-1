import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:plutus_fe_prototype/models/budget_model.dart';
import 'package:plutus_fe_prototype/models/transaction_model.dart';
import 'package:plutus_fe_prototype/services/interfaces/i_budget_service.dart';
import 'package:plutus_fe_prototype/services/interfaces/i_transaction_service.dart';
import 'package:plutus_fe_prototype/services/budget_notification_service.dart';

class BudgetProvider extends ChangeNotifier {
  final IBudgetService _budgetService;
  final BudgetNotificationService _notificationService;
  final ITransactionService _transactionService;
  StreamSubscription<Budget?>? _budgetSubscription;
  StreamSubscription<List<Transaction>>? _transactionSubscription;

  // Private state
  Budget? _activeBudget;
  List<CategorySpending> _categorySpending = [];
  List<UnbudgetedEntry> _unbudgetedSpending = [];
  List<BudgetAlert> _alerts = [];
  late DateTime _currentPeriodStart;
  late DateTime _currentPeriodEnd;
  bool _isLoading = false;
  String? _error;

  BudgetProvider({
    required IBudgetService budgetService,
    required BudgetNotificationService notificationService,
    required ITransactionService transactionService,
  })  : _budgetService = budgetService,
        _notificationService = notificationService,
        _transactionService = transactionService {
    final now = DateTime.now();
    _currentPeriodStart = DateTime(now.year, now.month, 1);
    _currentPeriodEnd = DateTime(now.year, now.month + 1, 1);

    _budgetSubscription = _budgetService.budgetStream.listen((_) {
      refreshSpending();
    });

    // Also refresh when transactions change (add/edit/delete)
    _transactionSubscription = _transactionService.transactionStream.listen((_) {
      refreshSpending();
    });
  }

  // Getters
  Budget? get activeBudget => _activeBudget;
  List<CategorySpending> get categorySpending =>
      List.unmodifiable(_categorySpending);
  List<UnbudgetedEntry> get unbudgetedSpending =>
      List.unmodifiable(_unbudgetedSpending);
  List<BudgetAlert> get alerts => List.unmodifiable(_alerts);
  DateTime get currentPeriodStart => _currentPeriodStart;
  DateTime get currentPeriodEnd => _currentPeriodEnd;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Computed getters
  double get totalBudgeted =>
      _categorySpending.fold(0.0, (sum, cs) => sum + cs.budgetedAmount);

  double get totalSpent =>
      _categorySpending.fold(0.0, (sum, cs) => sum + cs.spent);

  double get totalRemaining => totalBudgeted - totalSpent;

  double get overallProgress {
    final budgeted = totalBudgeted;
    if (budgeted <= 0) return 0.0;
    return (totalSpent / budgeted).clamp(0.0, 1.5);
  }

  int get overBudgetCount =>
      _categorySpending.where((cs) => cs.status == BudgetStatus.overBudget).length;

  int get warningCount =>
      _categorySpending.where((cs) => cs.status == BudgetStatus.warning).length;

  void setCurrentUser(int userId) {
    _budgetService.setCurrentUser(userId);
  }

  Future<void> loadBudget() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final budget = await _budgetService.getActiveBudget();
      _activeBudget = budget;

      if (budget != null) {
        _updatePeriodBounds();
        await _computeSpending();
      } else {
        _categorySpending = [];
        _unbudgetedSpending = [];
        _alerts = [];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> navigatePeriod(int direction) async {
    final budget = _activeBudget;
    if (budget == null) return;

    switch (budget.periodType) {
      case BudgetPeriodType.monthly:
        _currentPeriodStart = DateTime(
          _currentPeriodStart.year,
          _currentPeriodStart.month + direction,
          1,
        );
        _currentPeriodEnd = DateTime(
          _currentPeriodEnd.year,
          _currentPeriodEnd.month + direction,
          1,
        );
        break;
      case BudgetPeriodType.weekly:
        _currentPeriodStart =
            _currentPeriodStart.add(Duration(days: 7 * direction));
        _currentPeriodEnd =
            _currentPeriodEnd.add(Duration(days: 7 * direction));
        break;
      case BudgetPeriodType.biweekly:
        _currentPeriodStart =
            _currentPeriodStart.add(Duration(days: 14 * direction));
        _currentPeriodEnd =
            _currentPeriodEnd.add(Duration(days: 14 * direction));
        break;
    }

    await refreshSpending();
  }

  Future<void> quickUpdateAmount(int categoryId, double newAmount) async {
    await _budgetService.updateCategory(categoryId, budgetedAmount: newAmount);
    await refreshSpending();
  }

  Future<void> refreshSpending() async {
    if (_activeBudget == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _computeSpending();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updatePeriodBounds() {
    final budget = _activeBudget;
    if (budget == null) return;

    final now = DateTime.now();

    switch (budget.periodType) {
      case BudgetPeriodType.monthly:
        _currentPeriodStart = DateTime(now.year, now.month, 1);
        _currentPeriodEnd = DateTime(now.year, now.month + 1, 1);
        break;
      case BudgetPeriodType.weekly:
        // Start of current week (Monday)
        final daysFromMonday = now.weekday - 1;
        _currentPeriodStart = DateTime(
          now.year,
          now.month,
          now.day - daysFromMonday,
        );
        _currentPeriodEnd = _currentPeriodStart.add(const Duration(days: 7));
        break;
      case BudgetPeriodType.biweekly:
        // Use budget periodStart as anchor if available
        final anchor = budget.periodStart ?? DateTime(now.year, now.month, 1);
        final daysDiff = now.difference(anchor).inDays;
        final periodsElapsed = (daysDiff / 14).floor();
        _currentPeriodStart =
            anchor.add(Duration(days: periodsElapsed * 14));
        _currentPeriodEnd =
            _currentPeriodStart.add(const Duration(days: 14));
        break;
    }
  }

  Future<void> _computeSpending() async {
    final budget = _activeBudget;
    if (budget == null) return;

    // 1. Get all category spending map from service
    final spendingMap = await _budgetService.getAllCategorySpending(
      budget.id!,
      _currentPeriodStart,
      _currentPeriodEnd,
    );

    // 2. Build CategorySpending list for each category
    final spendingList = <CategorySpending>[];
    for (final category in budget.categories) {
      final categoryId = category.id!;
      final spent = spendingMap[categoryId] ?? 0.0;

      // Get period record
      final period = await _budgetService.getPeriodForCategory(
        categoryId,
        _currentPeriodStart,
      );

      // Compute effective budget (period override or category default)
      final effectiveBudget = period?.budgetedAmount ?? category.budgetedAmount;
      final remaining = effectiveBudget - spent;

      // Projected spending
      final projected = _budgetService.getProjectedSpending(
        spent,
        _currentPeriodStart,
        _currentPeriodEnd,
      );

      // Status based on percentage of budget used
      final percentage =
          effectiveBudget > 0 ? spent / effectiveBudget : 0.0;
      final status = BudgetStatus.fromPercentage(percentage);

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
    _categorySpending = spendingList;

    // 3. Get unbudgeted spending
    _unbudgetedSpending = await _budgetService.getUnbudgetedSpending(
      budget.id!,
      _currentPeriodStart,
      _currentPeriodEnd,
    );

    // 4. Check notification thresholds for alerts
    _alerts = await _notificationService.checkThresholds(
      budget.id!,
      _currentPeriodStart,
      _currentPeriodEnd,
    );
  }

  @override
  void dispose() {
    _budgetSubscription?.cancel();
    _transactionSubscription?.cancel();
    super.dispose();
  }
}
