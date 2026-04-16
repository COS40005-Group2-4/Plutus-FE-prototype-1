import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/service_locator.dart';
import '../models/transaction_model.dart';
import '../models/investment_model.dart';
import '../models/bill_model.dart';
import '../models/budget_model.dart';
import '../services/interfaces/interfaces.dart';
import 'auth_notifier.dart';

// ---------------------------------------------------------------------------
// DashboardData
// ---------------------------------------------------------------------------

class DashboardData {
  final List<Transaction> recentTransactions;
  final List<InvestmentModel> investments;
  final List<Bill> upcomingBills;
  final Budget? activeBudget;

  const DashboardData({
    required this.recentTransactions,
    required this.investments,
    required this.upcomingBills,
    required this.activeBudget,
  });

  /// Empty/unauthenticated state.
  const DashboardData.empty()
      : recentTransactions = const [],
        investments = const [],
        upcomingBills = const [],
        activeBudget = null;
}

// ---------------------------------------------------------------------------
// DashboardDataNotifier
// ---------------------------------------------------------------------------

class DashboardDataNotifier extends AsyncNotifier<DashboardData> {
  StreamSubscription<dynamic>? _transactionSub;
  StreamSubscription<dynamic>? _billSub;
  StreamSubscription<dynamic>? _budgetSub;
  StreamSubscription<dynamic>? _investmentSub;

  @override
  Future<DashboardData> build() async {
    final AuthState authState = ref.watch(authNotifierProvider);

    if (authState is! AuthAuthenticated) {
      return const DashboardData.empty();
    }

    final transactionService = sl<ITransactionService>();
    final investmentService = sl<IInvestmentService>();
    final billService = sl<IBillService>();
    final budgetService = sl<IBudgetService>();

    // Listen to data change streams — refresh everything when anything changes
    _transactionSub?.cancel();
    _billSub?.cancel();
    _budgetSub?.cancel();
    _investmentSub?.cancel();

    _transactionSub =
        transactionService.transactionStream.listen((_) => ref.invalidateSelf());
    _investmentSub =
        investmentService.onChanged.listen((_) => ref.invalidateSelf());
    _billSub = billService.billStream.listen((_) => ref.invalidateSelf());
    _budgetSub = budgetService.budgetStream.listen((_) => ref.invalidateSelf());

    ref.onDispose(() {
      _transactionSub?.cancel();
      _investmentSub?.cancel();
      _billSub?.cancel();
      _budgetSub?.cancel();
    });

    final results = await Future.wait([
      transactionService.getTransactions(),
      investmentService.getInvestmentList(),
      billService.getBills(),
      budgetService.getActiveBudget(),
    ]);

    final List<Transaction> allTransactions =
        results[0] as List<Transaction>;
    final List<InvestmentModel> investments =
        results[1] as List<InvestmentModel>;
    final List<Bill> bills = results[2] as List<Bill>;
    final Budget? activeBudget = results[3] as Budget?;

    // Take the most recent 20 transactions.
    final List<Transaction> recentTransactions = allTransactions.length > 20
        ? allTransactions.sublist(allTransactions.length - 20)
        : allTransactions;

    return DashboardData(
      recentTransactions: recentTransactions,
      investments: investments,
      upcomingBills: bills,
      activeBudget: activeBudget,
    );
  }

  /// Force a full reload of all dashboard data.
  void refresh() {
    ref.invalidateSelf();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final dashboardDataProvider =
    AsyncNotifierProvider<DashboardDataNotifier, DashboardData>(
  DashboardDataNotifier.new,
);
