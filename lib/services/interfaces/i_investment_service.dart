import 'dart:async';
import '../../models/investment_model.dart';

abstract class IInvestmentService {
  void setUserId(int userId);
  Future<List<InvestmentModel>> getInvestmentList({bool forceRefresh = false});
  Future<InvestmentModel> getInvestmentDetail(String commodity);
  void clearCache();
  Future<void> deleteInvestment(String investmentId);
  Future<String> saveInvestment(InvestmentModel investment);
  double getTotalPortfolioValue(List<InvestmentModel> investments);
  double getTotalGainLoss(List<InvestmentModel> investments);
  Future<InvestmentModel> refreshPriceData(InvestmentModel investment);
  Future<Map<String, dynamic>> getInvestmentReport({String? currency});
  Future<List<Map<String, dynamic>>> getUnsyncedInvestments(int userId);
  Future<void> markInvestmentAsSynced(String investmentId);

  /// Stream that fires whenever investment data changes (save/delete).
  Stream<void> get onChanged;
}
