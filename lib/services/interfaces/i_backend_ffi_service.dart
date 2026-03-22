abstract class IBackendFfiService {
  bool get isAvailable;

  Future<List<Map<String, dynamic>>> getTransactions();
  Future<void> saveTransaction(Map<String, dynamic> transaction);
  Future<void> importFile(String filePath);
  Future<Map<String, dynamic>> getRoiData({String? currency});
  Future<Map<String, dynamic>> getInvestmentList();
  Future<Map<String, dynamic>> getInvestmentDetail(String commodity);
  Future<void> deleteInvestment(String investmentId);
  Future<String> saveInvestment(Map<String, dynamic> investmentData);
}
