import '../../models/transaction_model.dart';

abstract class ITransactionService {
  Stream<List<Transaction>> get transactionStream;

  List<Transaction> getLastCachedTransactions();
  void setCurrentUser(int userId);
  void notifyTransactionUpdate();
  Future<List<Transaction>> getTransactions();
  Future<void> importTransactionFile(String filePath);
  Future<void> importTransaction(Map<String, dynamic> transaction);
  Future<Map<String, dynamic>> parseJsonFile(String jsonContent);
  Future<List<Map<String, dynamic>>> parseCsvFile(String csvContent);
  Future<List<Map<String, dynamic>>> parseXmlFile(String xmlContent);
  Future<List<Map<String, dynamic>>> parseLedgerFile(String ledgerContent);
  Future<List<Map<String, dynamic>>> getUnsyncedTransactions();
  Future<void> syncPendingTransactions();
  void dispose();
}
