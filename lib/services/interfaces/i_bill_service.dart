import '../../models/bill_model.dart';

abstract class IBillService {
  Stream<List<Bill>> get billStream;

  void setCurrentUser(int userId);
  Future<void> notifyBillUpdate();
  Future<List<Bill>> getBills();
  Future<void> addBill(Bill bill);
  Future<void> updateBill(Bill bill);
  Future<void> deleteBill(int billId);
  Future<void> markBillAsPaid(int billId);
  Future<double> getTotalDueAmount({required String currency, int days = 30});
  void dispose();
}
