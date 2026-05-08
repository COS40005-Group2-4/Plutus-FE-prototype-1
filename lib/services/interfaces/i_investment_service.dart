import 'dart:async';
import '../../models/investment_model.dart';
import '../../models/investment_price_point.dart';
import '../../models/investment_sale.dart';

class RecordSaleResult {
  final InvestmentSale sale;
  final InvestmentModel updatedInvestment;
  final String transactionId;

  const RecordSaleResult({
    required this.sale,
    required this.updatedInvestment,
    required this.transactionId,
  });
}

abstract class IInvestmentService {
  void setUserId(int userId);
  Future<List<InvestmentModel>> getInvestmentList({bool forceRefresh = false});
  Future<List<InvestmentModel>> getActiveInvestments({bool forceRefresh = false});
  Future<List<InvestmentModel>> getClosedInvestments({bool forceRefresh = false});
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

  // Manual price points
  Future<InvestmentPricePoint> addPricePoint({
    required String investmentId,
    required DateTime date,
    required double price,
    String? note,
  });
  Future<List<InvestmentPricePoint>> getPricePoints(String investmentId);
  Future<void> deletePricePoint(int pointId);

  // Sales
  Future<RecordSaleResult> recordSale({
    required String investmentId,
    required double quantity,
    required double pricePerUnit,
    required DateTime date,
    required String cashAccount,
    String? notes,
  });
  Future<List<InvestmentSale>> getSales(String investmentId);

  /// Stream that fires whenever investment data changes (save/delete/sale).
  Stream<void> get onChanged;
}
